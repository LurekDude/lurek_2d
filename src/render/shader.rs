//! WGSL user shader compilation, validation, and source-rewriting for the engine
//! custom shader system. Parses fragment entry signatures via `naga`, rewrites
//! `@fragment` entries as helper functions for the wrapper pipeline, and stores
//! per-shader uniform values. Does not hold wgpu pipelines — `GpuRenderer` builds those.

use crate::log_msg;
use crate::runtime::log_messages::SH01_SHADER_OK;
use std::collections::HashMap;
use wgpu::naga::{Binding, ScalarKind, TypeInner, VectorSize};
/// Fragment input location slot decoded from a user shader entry point.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum ShaderFragmentInput {
    /// `@location(0) vec4<f32>` RGBA color input.
    Color,
    /// `@location(1) vec2<f32>` UV coordinate input.
    Uv,
}
/// Rewritten fragment source and its entry name, ready for injection into the wrapper pipeline.
#[derive(Debug, Clone)]
struct PreparedFragmentSource {
    /// WGSL source with `@fragment` attribute stripped for helper-function wrapping.
    source: String,
    /// Original fragment function name preserved for wrapper call.
    entry_name: String,
    /// Ordered list of input slots actually used by this entry.
    inputs: Vec<ShaderFragmentInput>,
}
/// Name and input slots extracted from a validated fragment entry point.
#[derive(Debug, Clone)]
struct FragmentEntrySignature {
    /// Entry function name from the parsed `naga::Module`.
    name: String,
    /// Ordered input slots determined from `@location` bindings.
    inputs: Vec<ShaderFragmentInput>,
}
/// A compiled and validated user WGSL shader with its rewritten source and uniform map.
#[derive(Debug, Clone)]
pub struct Shader {
    /// Original WGSL source as supplied by the game.
    pub source: String,
    /// Rewritten source with `@fragment` stripped for pipeline wrapper injection.
    pub(crate) wrapper_source: String,
    /// Name of the fragment entry function in the rewritten source.
    pub(crate) fragment_entry_name: String,
    /// Ordered list of input slots the fragment function accepts.
    pub(crate) fragment_inputs: Vec<ShaderFragmentInput>,
    /// Named uniform values set by `send()`; forwarded to the GPU each frame.
    pub uniforms: HashMap<String, UniformValue>,
}
/// A typed uniform value sent to a `Shader` via `send()`.
#[derive(Debug, Clone)]
pub enum UniformValue {
    /// 32-bit float scalar.
    Float(f32),
    /// Two-component float vector.
    Vec2([f32; 2]),
    /// Three-component float vector.
    Vec3([f32; 3]),
    /// Four-component float vector.
    Vec4([f32; 4]),
    /// 32-bit signed integer.
    Int(i32),
    /// Boolean.
    Bool(bool),
}
impl Shader {
    /// Parse, validate, and prepare `source`; return error string on WGSL validation failure.
    pub fn new(source: String) -> Result<Self, String> {
        validate_wgsl(&source)?;
        let prepared = prepare_fragment_source_for_wrapper(&source)?;
        log_msg!(info, SH01_SHADER_OK);
        Ok(Self {
            source,
            wrapper_source: prepared.source,
            fragment_entry_name: prepared.entry_name,
            fragment_inputs: prepared.inputs,
            uniforms: HashMap::new(),
        })
    }
    /// Set or replace the named uniform value used on subsequent frames.
    pub fn send(&mut self, name: String, value: UniformValue) {
        self.uniforms.insert(name, value);
    }
    /// Return `true` when a uniform with `name` has been set.
    pub fn has_uniform(&self, name: &str) -> bool {
        self.uniforms.contains_key(name)
    }
    /// Return all set uniforms sorted alphabetically by name for deterministic GPU upload order.
    pub(crate) fn ordered_uniforms(&self) -> Vec<(&str, &UniformValue)> {
        let mut uniforms: Vec<_> = self
            .uniforms
            .iter()
            .map(|(name, value)| (name.as_str(), value))
            .collect();
        uniforms.sort_by(|(left, _), (right, _)| left.cmp(right));
        uniforms
    }
    /// Return the rewritten wrapper source for injection into the GPU pipeline.
    pub(crate) fn wrapper_source(&self) -> &str {
        &self.wrapper_source
    }
    /// Return the fragment helper function name within `wrapper_source`.
    pub(crate) fn fragment_entry_name(&self) -> &str {
        &self.fragment_entry_name
    }
    /// Return the ordered input slots accepted by the fragment entry.
    pub(crate) fn fragment_inputs(&self) -> &[ShaderFragmentInput] {
        &self.fragment_inputs
    }
}
/// Parse `source` and confirm it contains a valid fragment entry point; return error on failure.
fn validate_wgsl(source: &str) -> Result<(), String> {
    let module = wgpu::naga::front::wgsl::parse_str(source).map_err(|err| err.to_string())?;
    fragment_entry_signature(&module)?;
    Ok(())
}
/// Parse `source`, extract the fragment signature, and rewrite it as a helper function.
fn prepare_fragment_source_for_wrapper(source: &str) -> Result<PreparedFragmentSource, String> {
    let module = wgpu::naga::front::wgsl::parse_str(source).map_err(|err| err.to_string())?;
    let signature = fragment_entry_signature(&module)?;
    let rewritten = rewrite_fragment_entry_as_helper(source, &signature.name)?;
    Ok(PreparedFragmentSource {
        source: rewritten,
        entry_name: signature.name,
        inputs: signature.inputs,
    })
}
/// Locate the `@fragment` entry in `module` and return its name and input slots.
fn fragment_entry_signature(module: &wgpu::naga::Module) -> Result<FragmentEntrySignature, String> {
    let entry = module
        .entry_points
        .iter()
        .find(|entry| entry.stage == wgpu::naga::ShaderStage::Fragment)
        .ok_or_else(|| "shader source must define a fragment entry point".to_string())?;
    let inputs = entry
        .function
        .arguments
        .iter()
        .map(|argument| {
            match argument.binding {
            Some(Binding::Location { location, .. }) => match location {
                0 => validate_vec4_f32(module, argument.ty).map(|_| ShaderFragmentInput::Color),
                1 => validate_vec2_f32(module, argument.ty).map(|_| ShaderFragmentInput::Uv),
                _ => Err(format!(
                    "shader fragment entry point uses unsupported input @location({location})"
                )),
            },
            _ => Err(
                "shader fragment entry point inputs must use @location(0) color and @location(1) uv"
                    .to_string(),
            ),
        }
        })
        .collect::<Result<Vec<_>, _>>()?;
    let result = entry.function.result.as_ref().ok_or_else(|| {
        "shader fragment entry point must return @location(0) vec4<f32>".to_string()
    })?;
    match result.binding {
        Some(Binding::Location { location: 0, .. }) => validate_vec4_f32(module, result.ty)?,
        _ => {
            return Err(
                "shader fragment entry point must return @location(0) vec4<f32>".to_string(),
            )
        }
    }
    Ok(FragmentEntrySignature {
        name: entry.name.clone(),
        inputs,
    })
}
/// Assert that `ty` resolves to `vec2<f32>` in `module`.
fn validate_vec2_f32(
    module: &wgpu::naga::Module,
    ty: wgpu::naga::Handle<wgpu::naga::Type>,
) -> Result<(), String> {
    validate_vector_type(module, ty, VectorSize::Bi, "vec2<f32>")
}
/// Assert that `ty` resolves to `vec4<f32>` in `module`.
fn validate_vec4_f32(
    module: &wgpu::naga::Module,
    ty: wgpu::naga::Handle<wgpu::naga::Type>,
) -> Result<(), String> {
    validate_vector_type(module, ty, VectorSize::Quad, "vec4<f32>")
}
/// Assert that `ty` resolves to a float vector of `size` in `module`.
fn validate_vector_type(
    module: &wgpu::naga::Module,
    ty: wgpu::naga::Handle<wgpu::naga::Type>,
    size: VectorSize,
    expected: &str,
) -> Result<(), String> {
    match &module.types[ty].inner {
        TypeInner::Vector { size: actual_size, scalar }
            if *actual_size == size && scalar.kind == ScalarKind::Float && scalar.width == 4 =>
        {
            Ok(())
        }
        _ => Err(format!(
            "shader fragment entry point must use {expected} values for its color, uv, and return types"
        )),
    }
}
/// Strip `@fragment` from the entry function header and rename it to a plain helper.
fn rewrite_fragment_entry_as_helper(source: &str, entry_name: &str) -> Result<String, String> {
    let fn_marker = format!("fn {entry_name}");
    let fn_start = source.find(&fn_marker).ok_or_else(|| {
        format!("shader fragment entry point '{entry_name}' could not be located in source")
    })?;
    let fragment_attr_start = find_fragment_attribute_start(source, fn_start).ok_or_else(|| {
        format!("shader fragment entry point '{entry_name}' is missing @fragment")
    })?;
    let fragment_attr_end = fragment_attr_start + "@fragment".len();
    let body_start = find_function_body_start(source, fn_start)?;
    let header = &source[fn_start..body_start];
    let rewritten_header = rewrite_entry_point_header(header, entry_name)?;
    Ok(format!(
        "{}{}{}{}",
        &source[..fragment_attr_start],
        &source[fragment_attr_end..fn_start],
        rewritten_header,
        &source[body_start..],
    ))
}
/// Search backwards from `fn_start` for the nearest `@fragment` attribute with only whitespace between.
fn find_fragment_attribute_start(source: &str, fn_start: usize) -> Option<usize> {
    let prefix = &source[..fn_start];
    prefix.rmatch_indices("@fragment").find_map(|(index, _)| {
        let attr_end = index + "@fragment".len();
        source[attr_end..fn_start]
            .chars()
            .all(char::is_whitespace)
            .then_some(index)
    })
}
/// Return the byte offset of the `{` that opens the function body.
fn find_function_body_start(source: &str, fn_start: usize) -> Result<usize, String> {
    source[fn_start..]
        .char_indices()
        .find_map(|(offset, ch)| (ch == '{').then_some(fn_start + offset))
        .ok_or_else(|| "shader fragment entry point is missing a function body".to_string())
}
/// Rewrite an entry-point function header by stripping `@location` attributes from params and return.
fn rewrite_entry_point_header(header: &str, entry_name: &str) -> Result<String, String> {
    let paren_start = header.find('(').ok_or_else(|| {
        format!("shader fragment entry point '{entry_name}' is missing parameters")
    })?;
    let paren_end = find_matching_paren(header, paren_start)?;
    let params = &header[paren_start + 1..paren_end];
    let params = split_top_level_commas(params)
        .into_iter()
        .map(strip_leading_attributes)
        .filter(|param| !param.is_empty())
        .collect::<Vec<_>>();
    let return_clause = header[paren_end + 1..].trim();
    let return_clause = if let Some(rest) = return_clause.strip_prefix("->") {
        let ty = strip_leading_attributes(rest);
        format!(" -> {ty}")
    } else {
        String::new()
    };
    if params.is_empty() {
        Ok(format!("fn {entry_name}(){return_clause} "))
    } else {
        Ok(format!(
            "fn {entry_name}(\n    {}\n){return_clause} ",
            params.join(",\n    ")
        ))
    }
}
/// Return the index of the `)` matching the `(` at `open_index`.
fn find_matching_paren(text: &str, open_index: usize) -> Result<usize, String> {
    let mut depth = 0usize;
    for (offset, ch) in text[open_index..].char_indices() {
        match ch {
            '(' => depth += 1,
            ')' => {
                depth -= 1;
                if depth == 0 {
                    return Ok(open_index + offset);
                }
            }
            _ => {}
        }
    }
    Err("shader fragment entry point has an unclosed parameter list".to_string())
}
/// Split `text` on top-level commas, ignoring commas inside `()`, `<>`, and `[]`.
fn split_top_level_commas(text: &str) -> Vec<&str> {
    let mut parts = Vec::new();
    let mut start = 0usize;
    let mut paren_depth = 0usize;
    let mut angle_depth = 0usize;
    let mut bracket_depth = 0usize;
    for (index, ch) in text.char_indices() {
        match ch {
            '(' => paren_depth += 1,
            ')' => paren_depth = paren_depth.saturating_sub(1),
            '<' => angle_depth += 1,
            '>' => angle_depth = angle_depth.saturating_sub(1),
            '[' => bracket_depth += 1,
            ']' => bracket_depth = bracket_depth.saturating_sub(1),
            ',' if paren_depth == 0 && angle_depth == 0 && bracket_depth == 0 => {
                parts.push(text[start..index].trim());
                start = index + ch.len_utf8();
            }
            _ => {}
        }
    }
    parts.push(text[start..].trim());
    parts
}
/// Strip all leading WGSL `@attribute` and `@attribute(...)` tokens from `text`.
fn strip_leading_attributes(text: &str) -> String {
    let mut remainder = text.trim();
    while remainder.starts_with('@') {
        remainder = consume_attribute(remainder).trim_start();
    }
    remainder.trim().to_string()
}
/// Consume one WGSL `@attr` or `@attr(...)` token at the start of `text` and return the remainder.
fn consume_attribute(text: &str) -> &str {
    let bytes = text.as_bytes();
    let mut index = 1usize;
    while index < bytes.len() {
        let ch = bytes[index] as char;
        if ch.is_ascii_alphanumeric() || ch == '_' {
            index += 1;
            continue;
        }
        if ch == '(' {
            let mut depth = 1usize;
            index += 1;
            while index < bytes.len() && depth > 0 {
                match bytes[index] as char {
                    '(' => depth += 1,
                    ')' => depth -= 1,
                    _ => {}
                }
                index += 1;
            }
        }
        break;
    }
    &text[index..]
}
