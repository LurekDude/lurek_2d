//! Custom WGSL shader support for Lurek2D.
//!
//! Allows Lua scripts to create and apply custom fragment shaders
//! with uniform variables.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for shader-related operations and data management.
//! Key types exported from this module: `ShaderFragmentInput`, `Shader`, `UniformValue`.
//! Primary functions: `new()`, `send()`, `has_uniform()`, `ordered_uniforms()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::runtime::log_messages::SH01_SHADER_OK;
use crate::log_msg;
use std::collections::HashMap;

use wgpu::naga::{Binding, ScalarKind, TypeInner, VectorSize};

/// Which fragment shader input the user's entry point expects.
///
/// # Variants
/// - `Color` — Color variant.
/// - `Uv` — Uv variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum ShaderFragmentInput {
    Color,
    Uv,
}

#[derive(Debug, Clone)]
struct PreparedFragmentSource {
    source: String,
    entry_name: String,
    inputs: Vec<ShaderFragmentInput>,
}

#[derive(Debug, Clone)]
struct FragmentEntrySignature {
    name: String,
    inputs: Vec<ShaderFragmentInput>,
}

/// Represents a compiled custom shader with its uniform values.
///
/// # Fields
/// - `source` — `String`.
/// - `wrapper_source` — `String`.
/// - `fragment_entry_name` — `String`.
/// - `fragment_inputs` — `Vec<ShaderFragmentInput>`.
/// - `uniforms` — `HashMap<String, UniformValue>`.
///
/// Currently stores shader source and uniforms. The GPU pipeline is
/// created lazily when the shader is first used during rendering.
#[derive(Debug, Clone)]
pub struct Shader {
    /// WGSL source code (fragment shader body).
    pub source: String,
    pub(crate) wrapper_source: String,
    pub(crate) fragment_entry_name: String,
    pub(crate) fragment_inputs: Vec<ShaderFragmentInput>,
    /// Current uniform values set from Lua.
    pub uniforms: HashMap<String, UniformValue>,
}

/// A uniform value that can be sent to a shader from Lua.
///
/// # Variants
/// - `Float` — Float variant.
/// - `Vec2` — Vec2 variant.
/// - `Vec3` — Vec3 variant.
/// - `Vec4` — Vec4 variant.
/// - `Int` — Int variant.
/// - `Bool` — Bool variant.
#[derive(Debug, Clone)]
pub enum UniformValue {
    /// Single float value.
    Float(f32),
    /// 2-component vector.
    Vec2([f32; 2]),
    /// 3-component vector.
    Vec3([f32; 3]),
    /// 4-component vector (color, etc).
    Vec4([f32; 4]),
    /// Integer value.
    Int(i32),
    /// Boolean value.
    Bool(bool),
}

impl Shader {
    /// Creates a new shader from WGSL source code.
    ///
    /// # Parameters
    /// - `source` — `String`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
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

    /// Sets a uniform value by name. Delivery is immediate and synchronous; all connected handlers run before this method returns.
    ///
    /// # Parameters
    /// - `name` — `String`.
    /// - `value` — `UniformValue`.
    pub fn send(&mut self, name: String, value: UniformValue) {
        self.uniforms.insert(name, value);
    }

    /// Returns whether a uniform with the given name has been set.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_uniform(&self, name: &str) -> bool {
        self.uniforms.contains_key(name)
    }

    /// Returns the current uniforms sorted by name for stable GPU binding order.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    ///
    /// # Returns
    /// `Vec<(&str, &UniformValue)>`.
    pub(crate) fn ordered_uniforms(&self) -> Vec<(&str, &UniformValue)> {
        let mut uniforms: Vec<_> = self
            .uniforms
            .iter()
            .map(|(name, value)| (name.as_str(), value))
            .collect();
        uniforms.sort_by(|(left, _), (right, _)| left.cmp(right));
        uniforms
    }

    /// Returns the wrapper WGSL source that calls the user's fragment entry.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    ///
    /// # Returns
    /// `&str`.
    pub(crate) fn wrapper_source(&self) -> &str {
        &self.wrapper_source
    }

    /// Returns the name of the user's fragment entry point.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    ///
    /// # Returns
    /// `&str`.
    pub(crate) fn fragment_entry_name(&self) -> &str {
        &self.fragment_entry_name
    }

    /// Returns the ordered list of inputs the fragment entry expects.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    ///
    /// # Returns
    /// `&[ShaderFragmentInput]`.
    pub(crate) fn fragment_inputs(&self) -> &[ShaderFragmentInput] {
        &self.fragment_inputs
    }
}

fn validate_wgsl(source: &str) -> Result<(), String> {
    let module = wgpu::naga::front::wgsl::parse_str(source).map_err(|err| err.to_string())?;
    fragment_entry_signature(&module)?;
    Ok(())
}

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

fn validate_vec2_f32(
    module: &wgpu::naga::Module,
    ty: wgpu::naga::Handle<wgpu::naga::Type>,
) -> Result<(), String> {
    validate_vector_type(module, ty, VectorSize::Bi, "vec2<f32>")
}

fn validate_vec4_f32(
    module: &wgpu::naga::Module,
    ty: wgpu::naga::Handle<wgpu::naga::Type>,
) -> Result<(), String> {
    validate_vector_type(module, ty, VectorSize::Quad, "vec4<f32>")
}

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

fn find_function_body_start(source: &str, fn_start: usize) -> Result<usize, String> {
    source[fn_start..]
        .char_indices()
        .find_map(|(offset, ch)| (ch == '{').then_some(fn_start + offset))
        .ok_or_else(|| "shader fragment entry point is missing a function body".to_string())
}

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

fn strip_leading_attributes(text: &str) -> String {
    let mut remainder = text.trim();
    while remainder.starts_with('@') {
        remainder = consume_attribute(remainder).trim_start();
    }
    remainder.trim().to_string()
}

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

#[cfg(test)]
mod tests {
    use super::*;

    const VALID_WGSL_FRAGMENT_SHADER: &str = r#"
@fragment
fn fs_main(
    @location(0) color: vec4<f32>,
    @location(1) _uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    return color;
}
"#;

    const NO_FRAGMENT_WGSL: &str = r#"
fn helper(color: vec4<f32>) -> vec4<f32> {
    return color;
}
"#;

    #[test]
    fn test_phase02_live_shader_requires_fragment_entry_point() {
        let result = validate_wgsl(NO_FRAGMENT_WGSL);

        assert_eq!(
            result.unwrap_err(),
            "shader source must define a fragment entry point"
        );
    }

    #[test]
    fn test_phase02_live_shader_orders_uniforms_stably_for_gpu_binding() {
        let mut shader = Shader::new(VALID_WGSL_FRAGMENT_SHADER.to_string())
            .expect("expected valid fragment shader");
        shader.send("zeta".to_string(), UniformValue::Float(1.0));
        shader.send("alpha".to_string(), UniformValue::Vec2([2.0, 3.0]));
        shader.send("middle".to_string(), UniformValue::Bool(true));

        let ordered = shader.ordered_uniforms();
        let names: Vec<_> = ordered.iter().map(|(name, _)| *name).collect();

        assert_eq!(names, vec!["alpha", "middle", "zeta"]);
    }

    #[test]
    fn test_phase02_live_shader_rewrites_fragment_entry_for_wrapper_calls() {
        let prepared = prepare_fragment_source_for_wrapper(VALID_WGSL_FRAGMENT_SHADER)
            .expect("expected wrapper-compatible shader source");

        assert_eq!(prepared.entry_name, "fs_main");
        assert_eq!(
            prepared.inputs,
            vec![ShaderFragmentInput::Color, ShaderFragmentInput::Uv]
        );
        assert!(!prepared.source.contains("@fragment\nfn fs_main"));
        assert!(prepared.source.contains("fn fs_main("));
        wgpu::naga::front::wgsl::parse_str(&prepared.source)
            .expect("rewritten fragment helper should remain valid WGSL");
    }
}
