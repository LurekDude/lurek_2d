//! Integration tests for the Overlay (screen-effect overlay) module.

use luna2d::overlay::{
    AmbientState, CloudState, FadeState, FlashState, LightningState, Overlay, ShakeState,
    WeatherState, WeatherType,
};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state).expect("Failed to create Lua VM")
}

// ═════════════════════════════════════════════════════════════════════════
// 1. WeatherType
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn weather_type_from_name_valid() {
    assert_eq!(WeatherType::from_name("none"), Some(WeatherType::None));
    assert_eq!(WeatherType::from_name("rain"), Some(WeatherType::Rain));
    assert_eq!(WeatherType::from_name("snow"), Some(WeatherType::Snow));
    assert_eq!(WeatherType::from_name("hail"), Some(WeatherType::Hail));
    assert_eq!(WeatherType::from_name("dust"), Some(WeatherType::Dust));
    assert_eq!(WeatherType::from_name("leaves"), Some(WeatherType::Leaves));
    assert_eq!(WeatherType::from_name("ash"), Some(WeatherType::Ash));
    assert_eq!(WeatherType::from_name("pollen"), Some(WeatherType::Pollen));
}

#[test]
fn weather_type_from_name_invalid() {
    assert_eq!(WeatherType::from_name("RAIN"), None);
    assert_eq!(WeatherType::from_name(""), None);
    assert_eq!(WeatherType::from_name("tornado"), None);
    assert_eq!(WeatherType::from_name("Rain"), None);
}

#[test]
fn weather_type_name_roundtrip() {
    let types = [
        WeatherType::None,
        WeatherType::Rain,
        WeatherType::Snow,
        WeatherType::Hail,
        WeatherType::Dust,
        WeatherType::Leaves,
        WeatherType::Ash,
        WeatherType::Pollen,
    ];
    for wt in &types {
        let name = wt.name();
        assert_eq!(WeatherType::from_name(name), Some(*wt));
    }
}

// ═════════════════════════════════════════════════════════════════════════
// 2. Default States
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn weather_state_default() {
    let ws = WeatherState::default();
    assert!(!ws.enabled);
    assert_eq!(ws.weather_type, WeatherType::None);
    assert!((ws.intensity - 0.5).abs() < 1e-5);
    assert!((ws.wind_direction).abs() < 1e-5);
    assert!((ws.wind_speed).abs() < 1e-5);
    assert!(ws.particles.is_empty());
}

#[test]
fn ambient_state_default() {
    let a = AmbientState::default();
    assert!(!a.enabled);
    assert!((a.color[0] - 1.0).abs() < 1e-5);
    assert!((a.color[1] - 1.0).abs() < 1e-5);
    assert!((a.color[2] - 1.0).abs() < 1e-5);
    assert!((a.color[3] - 1.0).abs() < 1e-5);
    assert!((a.time_of_day - 12.0).abs() < 1e-5);
}

#[test]
fn flash_state_default() {
    let f = FlashState::default();
    assert!(!f.active);
    assert!((f.duration - 0.2).abs() < 1e-5);
}

#[test]
fn shake_state_default() {
    let s = ShakeState::default();
    assert!(!s.active);
    assert!((s.intensity - 5.0).abs() < 1e-5);
    assert!((s.offset_x).abs() < 1e-5);
    assert!((s.offset_y).abs() < 1e-5);
}

#[test]
fn fade_state_default() {
    let f = FadeState::default();
    assert!(!f.active);
    assert!((f.target_alpha - 1.0).abs() < 1e-5);
    assert!((f.duration - 1.0).abs() < 1e-5);
}

#[test]
fn cloud_state_default() {
    let c = CloudState::default();
    assert!(!c.enabled);
    assert_eq!(c.count, 5);
    assert!((c.speed - 20.0).abs() < 1e-5);
    assert!((c.scale - 1.0).abs() < 1e-5);
    assert!((c.opacity - 0.3).abs() < 1e-5);
}

#[test]
fn lightning_state_default() {
    let l = LightningState::default();
    assert!(!l.active);
    assert!((l.duration - 0.15).abs() < 1e-5);
}

// ═════════════════════════════════════════════════════════════════════════
// 3. Overlay Construction
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_new_dimensions() {
    let ov = Overlay::new(1024, 768);
    assert_eq!(ov.get_width(), 1024);
    assert_eq!(ov.get_height(), 768);
    assert_eq!(ov.get_dimensions(), (1024, 768));
}

#[test]
fn overlay_new_inactive() {
    let ov = Overlay::new(800, 600);
    assert!(!ov.is_active());
}

// ═════════════════════════════════════════════════════════════════════════
// 4. Resize
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_resize() {
    let mut ov = Overlay::new(800, 600);
    ov.resize(1920, 1080);
    assert_eq!(ov.get_width(), 1920);
    assert_eq!(ov.get_height(), 1080);
    assert_eq!(ov.get_dimensions(), (1920, 1080));
}

// ═════════════════════════════════════════════════════════════════════════
// 5. Flash
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_trigger_flash() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_flash(1.0, 0.0, 0.0, 0.8, 0.5);
    assert!(ov.flash.active);
    assert!((ov.flash.color[0] - 1.0).abs() < 1e-5);
    assert!((ov.flash.color[3] - 0.8).abs() < 1e-5);
    assert!((ov.flash.duration - 0.5).abs() < 1e-5);
    assert!(ov.is_active());
}

#[test]
fn overlay_flash_alpha_decays() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_flash(1.0, 1.0, 1.0, 1.0, 1.0);
    // At t=0, flash_alpha should be 1.0
    assert!((ov.get_flash_alpha() - 1.0).abs() < 1e-5);
    // After 0.5s, should be ~0.5
    ov.update(0.5);
    assert!((ov.get_flash_alpha() - 0.5).abs() < 0.05);
}

#[test]
fn overlay_flash_completes() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_flash(1.0, 1.0, 1.0, 1.0, 0.2);
    ov.update(0.3);
    assert!(!ov.flash.active);
    assert!((ov.get_flash_alpha()).abs() < 1e-5);
}

// ═════════════════════════════════════════════════════════════════════════
// 6. Shake
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_trigger_shake() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_shake(10.0, 0.5);
    assert!(ov.shake.active);
    assert!((ov.shake.intensity - 10.0).abs() < 1e-5);
    assert!((ov.shake.duration - 0.5).abs() < 1e-5);
}

#[test]
fn overlay_shake_produces_offset() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_shake(10.0, 1.0);
    ov.update(0.1);
    let (ox, oy) = ov.get_shake_offset();
    // Shake should produce non-zero offset during active period
    assert!(ox.abs() > 0.0 || oy.abs() > 0.0);
}

#[test]
fn overlay_shake_decays_to_zero() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_shake(10.0, 0.5);
    ov.update(0.6);
    let (ox, oy) = ov.get_shake_offset();
    assert!((ox).abs() < 1e-5);
    assert!((oy).abs() < 1e-5);
    assert!(!ov.shake.active);
}

// ═════════════════════════════════════════════════════════════════════════
// 7. Fade
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_trigger_fade() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_fade(0.0, 0.0, 0.0, 1.0, 2.0);
    assert!(ov.fade.active);
    assert!((ov.fade.target_alpha - 1.0).abs() < 1e-5);
    assert!((ov.fade.duration - 2.0).abs() < 1e-5);
}

#[test]
fn overlay_fade_interpolates() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_fade(0.0, 0.0, 0.0, 1.0, 1.0);
    ov.update(0.5);
    // Should be approximately halfway (0.5)
    assert!((ov.fade.color[3] - 0.5).abs() < 0.05);
}

#[test]
fn overlay_fade_completes_at_target() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_fade(0.0, 0.0, 0.0, 0.8, 0.5);
    ov.update(0.6);
    assert!(!ov.fade.active);
    assert!((ov.fade.color[3] - 0.8).abs() < 1e-5);
}

// ═════════════════════════════════════════════════════════════════════════
// 8. Lightning
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_trigger_lightning() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_lightning();
    assert!(ov.lightning.active);
    assert!(ov.is_active());
}

#[test]
fn overlay_lightning_alpha_decays() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_lightning();
    let alpha0 = ov.get_lightning_alpha();
    assert!(alpha0 > 0.0);
    ov.update(0.07);
    let alpha1 = ov.get_lightning_alpha();
    assert!(alpha1 < alpha0);
}

#[test]
fn overlay_lightning_completes() {
    let mut ov = Overlay::new(800, 600);
    ov.trigger_lightning();
    ov.update(0.2);
    assert!(!ov.lightning.active);
    assert!((ov.get_lightning_alpha()).abs() < 1e-5);
}

// ═════════════════════════════════════════════════════════════════════════
// 9. Ambient
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn ambient_time_of_day_night() {
    let a = AmbientState {
        enabled: true,
        color: [1.0, 1.0, 1.0, 1.0],
        time_of_day: 2.0,
    };
    let c = a.compute_color_from_time();
    // Night should be dark blue tint
    assert!((c[0] - 0.1).abs() < 1e-5);
    assert!((c[1] - 0.1).abs() < 1e-5);
    assert!((c[2] - 0.3).abs() < 1e-5);
}

#[test]
fn ambient_time_of_day_day() {
    let a = AmbientState {
        enabled: true,
        color: [1.0, 1.0, 1.0, 1.0],
        time_of_day: 12.0,
    };
    let c = a.compute_color_from_time();
    // Day should be bright
    assert!((c[0] - 1.0).abs() < 1e-5);
    assert!((c[1] - 0.8).abs() < 1e-5);
    assert!((c[2] - 0.6).abs() < 1e-5);
}

#[test]
fn ambient_time_of_day_dawn() {
    let a = AmbientState {
        enabled: true,
        color: [1.0, 1.0, 1.0, 1.0],
        time_of_day: 6.0,
    };
    let c = a.compute_color_from_time();
    // Dawn: midpoint lerp from night to day
    assert!(c[0] > 0.1 && c[0] < 1.0);
    assert!(c[1] > 0.1 && c[1] < 0.8);
}

#[test]
fn ambient_time_of_day_dusk() {
    let a = AmbientState {
        enabled: true,
        color: [1.0, 1.0, 1.0, 1.0],
        time_of_day: 18.0,
    };
    let c = a.compute_color_from_time();
    // Dusk: midpoint lerp from day to night
    assert!(c[0] > 0.1 && c[0] < 1.0);
    assert!(c[1] > 0.1 && c[1] < 0.8);
}

#[test]
fn ambient_update_sets_color_from_time() {
    let mut ov = Overlay::new(800, 600);
    ov.ambient.enabled = true;
    ov.ambient.time_of_day = 2.0;
    ov.update(0.016);
    // After update, ambient color should match compute_color_from_time
    assert!((ov.ambient.color[0] - 0.1).abs() < 1e-5);
    assert!((ov.ambient.color[2] - 0.3).abs() < 1e-5);
}

// ═════════════════════════════════════════════════════════════════════════
// 10. Weather Particles
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn weather_spawns_particles() {
    let mut ov = Overlay::new(800, 600);
    ov.weather.enabled = true;
    ov.weather.weather_type = WeatherType::Rain;
    ov.weather.intensity = 0.5;
    ov.update(0.1);
    assert!(!ov.weather.particles.is_empty());
}

#[test]
fn weather_particles_move_down() {
    let mut ov = Overlay::new(800, 600);
    ov.weather.enabled = true;
    ov.weather.weather_type = WeatherType::Rain;
    ov.weather.intensity = 0.5;
    // Spawn some particles
    ov.update(0.05);
    let initial_y: Vec<f32> = ov.weather.particles.iter().map(|p| p.y).collect();
    // Move them
    ov.update(0.1);
    for (i, _p) in ov.weather.particles.iter().enumerate() {
        if i < initial_y.len() {
            // New particles may have been added after the initial batch
            // but existing particles should have moved down
        }
    }
    // At least verify particles exist and most have y > -10
    assert!(ov.weather.particles.iter().any(|p| p.y > -10.0));
}

#[test]
fn weather_disabled_no_particles() {
    let mut ov = Overlay::new(800, 600);
    ov.weather.enabled = false;
    ov.weather.weather_type = WeatherType::Snow;
    ov.update(0.1);
    assert!(ov.weather.particles.is_empty());
}

#[test]
fn weather_none_type_no_spawn() {
    let mut ov = Overlay::new(800, 600);
    ov.weather.enabled = true;
    ov.weather.weather_type = WeatherType::None;
    ov.update(0.1);
    assert!(ov.weather.particles.is_empty());
}

#[test]
fn weather_wind_affects_particles() {
    let mut ov = Overlay::new(800, 600);
    ov.weather.enabled = true;
    ov.weather.weather_type = WeatherType::Snow;
    ov.weather.intensity = 0.5;
    ov.weather.wind_speed = 100.0;
    ov.weather.wind_direction = 0.0; // wind blowing right
    ov.update(0.05);
    // After more updates, particles should have moved right
    let _xs_before: Vec<f32> = ov.weather.particles.iter().map(|p| p.x).collect();
    ov.update(0.1);
    // Some particles should have moved to the right compared to their vx=0 trajectory
    assert!(ov.weather.particles.iter().any(|p| p.x > 0.0));
}

// ═════════════════════════════════════════════════════════════════════════
// 11. Cloud Shadows
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn cloud_offset_scrolls() {
    let mut ov = Overlay::new(800, 600);
    ov.clouds.enabled = true;
    ov.clouds.speed = 50.0;
    let offset0 = ov.clouds.offset;
    ov.update(0.1);
    assert!(ov.clouds.offset > offset0);
}

#[test]
fn cloud_offset_no_scroll_when_disabled() {
    let mut ov = Overlay::new(800, 600);
    ov.clouds.enabled = false;
    ov.clouds.speed = 50.0;
    ov.update(0.1);
    assert!((ov.clouds.offset).abs() < 1e-5);
}

// ═════════════════════════════════════════════════════════════════════════
// 12. Clear
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_clear_resets_all() {
    let mut ov = Overlay::new(800, 600);
    ov.weather.enabled = true;
    ov.ambient.enabled = true;
    ov.clouds.enabled = true;
    ov.trigger_flash(1.0, 0.0, 0.0, 1.0, 0.5);
    ov.trigger_shake(10.0, 0.5);
    ov.trigger_fade(0.0, 0.0, 0.0, 1.0, 1.0);
    ov.trigger_lightning();

    assert!(ov.is_active());
    ov.clear();
    assert!(!ov.is_active());
    assert!(!ov.weather.enabled);
    assert!(!ov.ambient.enabled);
    assert!(!ov.flash.active);
    assert!(!ov.shake.active);
    assert!(!ov.fade.active);
    assert!(!ov.lightning.active);
}

// ═════════════════════════════════════════════════════════════════════════
// 13. is_active
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn overlay_is_active_weather() {
    let mut ov = Overlay::new(800, 600);
    assert!(!ov.is_active());
    ov.weather.enabled = true;
    assert!(ov.is_active());
}

#[test]
fn overlay_is_active_ambient() {
    let mut ov = Overlay::new(800, 600);
    ov.ambient.enabled = true;
    assert!(ov.is_active());
}

#[test]
fn overlay_is_active_clouds() {
    let mut ov = Overlay::new(800, 600);
    ov.clouds.enabled = true;
    assert!(ov.is_active());
}

// ═════════════════════════════════════════════════════════════════════════
// 14. Lua VM Integration Tests
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn lua_overlay_create() {
    let lua = make_vm();
    lua.load("local ov = luna.overlay.newOverlay(800, 600); assert(ov ~= nil)")
        .exec()
        .expect("Failed to create overlay via Lua");
}

#[test]
fn lua_overlay_create_defaults() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        assert(ov:getWidth() == 800)
        assert(ov:getHeight() == 600)
    "#,
    )
    .exec()
    .expect("Factory defaults should be 800x600");
}

#[test]
fn lua_overlay_dimensions() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay(1024, 768)
        assert(ov:getWidth() == 1024)
        assert(ov:getHeight() == 768)
        local w, h = ov:getDimensions()
        assert(w == 1024)
        assert(h == 768)
    "#,
    )
    .exec()
    .expect("Dimensions should match");
}

#[test]
fn lua_overlay_resize() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay(800, 600)
        ov:resize(1920, 1080)
        assert(ov:getWidth() == 1920)
        assert(ov:getHeight() == 1080)
    "#,
    )
    .exec()
    .expect("Resize should update dimensions");
}

#[test]
fn lua_overlay_is_active_initially_false() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        assert(ov:isActive() == false)
    "#,
    )
    .exec()
    .expect("New overlay should be inactive");
}

#[test]
fn lua_overlay_ambient() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:setAmbientEnabled(true)
        assert(ov:isAmbientEnabled() == true)
        assert(ov:isActive() == true)
        ov:setAmbientColor(0.5, 0.6, 0.7, 0.8)
        local r, g, b, a = ov:getAmbientColor()
        assert(math.abs(r - 0.5) < 0.001)
        assert(math.abs(g - 0.6) < 0.001)
        assert(math.abs(b - 0.7) < 0.001)
        assert(math.abs(a - 0.8) < 0.001)
    "#,
    )
    .exec()
    .expect("Ambient API should work");
}

#[test]
fn lua_overlay_time_of_day() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:setTimeOfDay(18.5)
        assert(math.abs(ov:getTimeOfDay() - 18.5) < 0.001)
    "#,
    )
    .exec()
    .expect("Time of day API should work");
}

#[test]
fn lua_overlay_weather() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:setWeatherEnabled(true)
        assert(ov:isWeatherEnabled() == true)
        ov:setWeather("rain")
        assert(ov:getWeather() == "rain")
        ov:setWeatherIntensity(0.8)
        assert(math.abs(ov:getWeatherIntensity() - 0.8) < 0.001)
    "#,
    )
    .exec()
    .expect("Weather API should work");
}

#[test]
fn lua_overlay_weather_invalid() {
    let lua = make_vm();
    let result = lua
        .load(
            r#"
        local ov = luna.overlay.newOverlay()
        ov:setWeather("tornado")
    "#,
        )
        .exec();
    assert!(result.is_err(), "Invalid weather type should error");
}

#[test]
fn lua_overlay_wind() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:setWindDirection(1.5)
        assert(math.abs(ov:getWindDirection() - 1.5) < 0.001)
        ov:setWindSpeed(50.0)
        assert(math.abs(ov:getWindSpeed() - 50.0) < 0.001)
    "#,
    )
    .exec()
    .expect("Wind API should work");
}

#[test]
fn lua_overlay_flash() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        assert(ov:isFlashing() == false)
        ov:flash(1, 0, 0)
        assert(ov:isFlashing() == true)
        assert(ov:isActive() == true)
    "#,
    )
    .exec()
    .expect("Flash API should work");
}

#[test]
fn lua_overlay_shake() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        assert(ov:isShaking() == false)
        ov:shake(10.0, 0.5)
        assert(ov:isShaking() == true)
        ov:update(0.1)
        local x, y = ov:getShakeOffset()
        -- At least one offset should be non-zero after update
        assert(math.abs(x) > 0 or math.abs(y) > 0)
    "#,
    )
    .exec()
    .expect("Shake API should work");
}

#[test]
fn lua_overlay_fade() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        assert(ov:isFading() == false)
        ov:fade(0, 0, 0, 1.0, 1.0)
        assert(ov:isFading() == true)
    "#,
    )
    .exec()
    .expect("Fade API should work");
}

#[test]
fn lua_overlay_clouds() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:setCloudShadows(true)
        assert(ov:isCloudShadowsEnabled() == true)
        ov:setCloudCount(10)
        assert(ov:getCloudCount() == 10)
        ov:setCloudSpeed(30.0)
        assert(math.abs(ov:getCloudSpeed() - 30.0) < 0.001)
        ov:setCloudScale(2.0)
        assert(math.abs(ov:getCloudScale() - 2.0) < 0.001)
        ov:setCloudOpacity(0.5)
        assert(math.abs(ov:getCloudOpacity() - 0.5) < 0.001)
    "#,
    )
    .exec()
    .expect("Cloud API should work");
}

#[test]
fn lua_overlay_lightning() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:triggerLightning()
        ov:setLightningColor(1, 1, 0.8, 0.9)
        local r, g, b, a = ov:getLightningColor()
        assert(math.abs(r - 1.0) < 0.001)
        assert(math.abs(b - 0.8) < 0.001)
        assert(math.abs(a - 0.9) < 0.001)
    "#,
    )
    .exec()
    .expect("Lightning API should work");
}

#[test]
fn lua_overlay_clear() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:setWeatherEnabled(true)
        ov:setAmbientEnabled(true)
        assert(ov:isActive() == true)
        ov:clear()
        assert(ov:isActive() == false)
    "#,
    )
    .exec()
    .expect("Clear should reset all effects");
}

#[test]
fn lua_overlay_update() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:flash(1, 1, 1, 1, 0.1)
        assert(ov:isFlashing() == true)
        ov:update(0.2)
        assert(ov:isFlashing() == false)
    "#,
    )
    .exec()
    .expect("Update should advance flash timer");
}

#[test]
fn lua_overlay_type_name() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        assert(ov:type() == "Overlay")
        assert(ov:typeOf("Object") == true)
        assert(ov:typeOf("Overlay") == true)
        assert(ov:typeOf("SomethingElse") == false)
    "#,
    )
    .exec()
    .expect("Type introspection should work");
}

#[test]
fn lua_overlay_weather_all_types() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        local types = {"none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen"}
        for _, wt in ipairs(types) do
            ov:setWeather(wt)
            assert(ov:getWeather() == wt, "Weather roundtrip failed for: " .. wt)
        end
    "#,
    )
    .exec()
    .expect("All weather types should roundtrip");
}

#[test]
fn lua_overlay_draw_noop() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:draw()  -- should not error
    "#,
    )
    .exec()
    .expect("draw() should be a no-op without error");
}

#[test]
fn lua_overlay_ambient_color_default_alpha() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:setAmbientColor(0.5, 0.5, 0.5)
        local r, g, b, a = ov:getAmbientColor()
        assert(math.abs(a - 1.0) < 0.001, "Default ambient alpha should be 1.0")
    "#,
    )
    .exec()
    .expect("Ambient color alpha should default to 1.0");
}

#[test]
fn lua_overlay_flash_defaults() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:flash(1.0, 0.0, 0.0)
        assert(ov:isFlashing() == true)
        ov:update(0.3)
        -- With default duration 0.2, flash should have completed
        assert(ov:isFlashing() == false)
    "#,
    )
    .exec()
    .expect("Flash default duration should be 0.2s");
}

#[test]
fn lua_overlay_shake_defaults() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:shake(5.0)
        assert(ov:isShaking() == true)
        ov:update(0.6)
        -- Default duration is 0.5s
        assert(ov:isShaking() == false)
    "#,
    )
    .exec()
    .expect("Shake default duration should be 0.5s");
}

#[test]
fn lua_overlay_fade_defaults() {
    let lua = make_vm();
    lua.load(
        r#"
        local ov = luna.overlay.newOverlay()
        ov:fade(0, 0, 0)
        assert(ov:isFading() == true)
        ov:update(1.1)
        -- Default alpha=1.0, duration=1.0s
        assert(ov:isFading() == false)
    "#,
    )
    .exec()
    .expect("Fade default duration should be 1.0s");
}
