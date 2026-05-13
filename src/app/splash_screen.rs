//! Scope: Splash-screen branding asset loading and rendering commands.
//! This file defines branding data types and command builders for the no-game splash screen.
//! It owns embedded texture decode and splash draw-command composition.

use super::app::fit_contain_size;
use crate::render::renderer::{DrawMode, RenderCommand, TextureData};
use crate::runtime::resource_keys::{FontKey, TextureKey};
use slotmap::SlotMap;

// ---- Type: SplashTexture ----

#[derive(Clone, Copy)]
/// Texture metadata used when drawing splash branding images.
pub struct SplashTexture {
    /// Texture handle stored in the splash texture map.
    pub texture_key: TextureKey,
    /// Source image width in pixels.
    pub width: u32,
    /// Source image height in pixels.
    pub height: u32,
}

// ---- Type: SplashBranding ----

/// Loaded splash branding resources kept for repeated frame rendering.
pub struct SplashBranding {
    /// Texture storage containing decoded embedded splash assets.
    pub textures: SlotMap<TextureKey, TextureData>,
    /// Large centered icon shown in the upper splash area.
    pub large_icon: SplashTexture,
    /// Banner image shown below the large icon.
    pub banner: SplashTexture,
}

// ---- Helper Functions: Splash Asset Loading ----

/// Loads embedded splash branding textures and returns them as a ready-to-draw bundle.
pub fn load_splash_branding() -> Option<SplashBranding> {
    let mut textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
    let large_icon = {
        let image = match ::image::load_from_memory(std::include_bytes!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/assets/icon-large.png"
        ))) {
            Ok(image) => image,
            Err(error) => {
                log::warn!(
                    "Failed to decode embedded splash texture '{}': {}",
                    "assets/svg/large_icon.png",
                    error
                );
                return None;
            }
        };

        let rgba = image.to_rgba8();
        let (width, height) = rgba.dimensions();
        match crate::image::Texture::from_rgba(width, height, rgba.into_raw(), &mut textures) {
            Ok(texture) => SplashTexture {
                texture_key: texture.key,
                width: texture.width,
                height: texture.height,
            },
            Err(error) => {
                log::warn!(
                    "Failed to prepare embedded splash texture '{}': {}",
                    "assets/svg/large_icon.png",
                    error
                );
                return None;
            }
        }
    };

    let banner = {
        let image = match ::image::load_from_memory(std::include_bytes!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/assets/banner.png"
        ))) {
            Ok(image) => image,
            Err(error) => {
                log::warn!(
                    "Failed to decode embedded splash texture '{}': {}",
                    "assets/svg/banner.png",
                    error
                );
                return None;
            }
        };

        let rgba = image.to_rgba8();
        let (width, height) = rgba.dimensions();
        match crate::image::Texture::from_rgba(width, height, rgba.into_raw(), &mut textures) {
            Ok(texture) => SplashTexture {
                texture_key: texture.key,
                width: texture.width,
                height: texture.height,
            },
            Err(error) => {
                log::warn!(
                    "Failed to prepare embedded splash texture '{}': {}",
                    "assets/svg/banner.png",
                    error
                );
                return None;
            }
        }
    };

    Some(SplashBranding {
        textures,
        large_icon,
        banner,
    })
}

#[allow(clippy::vec_init_then_push)]
/// Builds splash-screen render commands for branding and drag-and-drop hint text.
pub fn make_splash_commands(
    width: u32,
    height: u32,
    small_key: FontKey,
    fonts: &mut SlotMap<FontKey, crate::render::Font>,
    branding: Option<&SplashBranding>,
    drag_hover: bool,
) -> Vec<RenderCommand> {
    let width_f = width as f32;
    let height_f = height as f32;
    let cx = width_f / 2.0;
    let hint_text = if drag_hover {
        "Release to load game"
    } else {
        "Drop a game folder here to load it"
    };
    let hint_w = fonts
        .get_mut(small_key)
        .map(|f| f.text_width(hint_text))
        .unwrap_or(0.0);

    let top_margin = 24.0_f32;
    let hint_band_top = height_f - 82.0;

    let mut cmds: Vec<RenderCommand> = Vec::new();

    if let Some(branding) = branding {
        let (icon_w, icon_h) = fit_contain_size(
            branding.large_icon.width,
            branding.large_icon.height,
            width_f * 0.46,
            height_f * 0.40,
        );
        let (banner_w, banner_h) = fit_contain_size(
            branding.banner.width,
            branding.banner.height,
            width_f * 0.80,
            height_f * 0.22,
        );

        let banner_center_min = top_margin + banner_h * 0.5;
        let banner_center_max = (hint_band_top - 18.0 - banner_h * 0.5).max(banner_center_min);
        let banner_center_y = (height_f * 0.72).clamp(banner_center_min, banner_center_max);

        let icon_center_min = top_margin + icon_h * 0.5;
        let icon_center_max =
            (banner_center_y - banner_h * 0.5 - 32.0 - icon_h * 0.5).max(icon_center_min);
        let icon_center_y = (height_f * 0.33).clamp(icon_center_min, icon_center_max);

        cmds.push(RenderCommand::SetColor(1.0, 1.0, 1.0, 1.0));
        cmds.push(RenderCommand::DrawImageEx {
            texture_key: branding.large_icon.texture_key,
            x: cx,
            y: icon_center_y,
            rotation: 0.0,
            sx: icon_w / branding.large_icon.width as f32,
            sy: icon_h / branding.large_icon.height as f32,
            ox: branding.large_icon.width as f32 * 0.5,
            oy: branding.large_icon.height as f32 * 0.5,
            effect: None,
        });
        cmds.push(RenderCommand::DrawImageEx {
            texture_key: branding.banner.texture_key,
            x: cx,
            y: banner_center_y,
            rotation: 0.0,
            sx: banner_w / branding.banner.width as f32,
            sy: banner_h / branding.banner.height as f32,
            ox: branding.banner.width as f32 * 0.5,
            oy: branding.banner.height as f32 * 0.5,
            effect: None,
        });
    }

    if drag_hover {
        cmds.push(RenderCommand::SetColor(0.40, 0.80, 0.40, 0.15));
        cmds.push(RenderCommand::Rectangle {
            mode: DrawMode::Fill,
            x: cx - 220.0,
            y: height_f - 70.0,
            w: 440.0,
            h: 40.0,
        });
        cmds.push(RenderCommand::SetColor(0.50, 0.90, 0.50, 1.0));
    } else {
        cmds.push(RenderCommand::SetColor(0.35, 0.30, 0.45, 1.0));
    }
    cmds.push(RenderCommand::Print {
        font_key: small_key,
        text: hint_text.to_string(),
        x: cx - hint_w / 2.0,
        y: height_f - 55.0,
        scale: 1.0,
    });

    cmds
}
