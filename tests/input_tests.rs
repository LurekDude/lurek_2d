use luna2d::input::GamepadState;
use luna2d::input::KeyboardState;
use luna2d::input::MouseState;
use luna2d::input::SystemCursor;
use luna2d::input::TouchState;

#[test]
fn keyboard_key_down() {
    let mut kb = KeyboardState::new();
    kb.set_key_down("space");
    assert!(kb.is_down("space"));
    assert!(!kb.is_down("a"));
}

#[test]
fn keyboard_key_up() {
    let mut kb = KeyboardState::new();
    kb.set_key_down("a");
    kb.set_key_up("a");
    assert!(!kb.is_down("a"));
}

#[test]
fn keyboard_pressed_events() {
    let mut kb = KeyboardState::new();
    kb.begin_frame();
    kb.set_key_down("w");
    assert_eq!(kb.get_pressed().len(), 1);
    assert_eq!(kb.get_pressed()[0], "w");
}

// ── Gamepad tests ──────────────────────────────────────────────────

#[test]
fn gamepad_button_down() {
    let mut gp = GamepadState::new(0);
    gp.update_button(0, true);
    assert!(gp.is_button_pressed(0));
    assert!(!gp.is_button_pressed(1));
}

#[test]
fn gamepad_button_up() {
    let mut gp = GamepadState::new(0);
    gp.update_button(0, true);
    gp.update_button(0, false);
    assert!(!gp.is_button_pressed(0));
}

#[test]
fn gamepad_axis_value() {
    let mut gp = GamepadState::new(0);
    gp.update_axis(0, 0.75);
    assert!((gp.get_axis_value(0) - 0.75).abs() < 1e-5);
    assert!((gp.get_axis_value(1) - 0.0).abs() < 1e-5); // unset axis
}

// ── Gamepad Lua API tests ──────────────────────────────────────────

use luna2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone()).unwrap();
    (state, lua)
}

fn read_source(path: &str) -> String {
    std::fs::read_to_string(path).unwrap_or_else(|err| panic!("Failed to read {}: {}", path, err))
}

fn find_matching_brace(source: &str, open_index: usize) -> usize {
    let mut depth = 0usize;

    for (offset, ch) in source[open_index..].char_indices() {
        match ch {
            '{' => depth += 1,
            '}' => {
                depth -= 1;
                if depth == 0 {
                    return open_index + offset;
                }
            }
            _ => {}
        }
    }

    panic!(
        "No matching closing brace found for block starting at {}",
        open_index
    );
}

fn extract_braced_block<'a>(source: &'a str, marker: &str) -> &'a str {
    let marker_index = source
        .find(marker)
        .unwrap_or_else(|| panic!("Missing marker: {}", marker));
    let open_index = source[marker_index..]
        .find('{')
        .map(|offset| marker_index + offset)
        .unwrap_or_else(|| panic!("Missing opening brace after marker: {}", marker));
    let close_index = find_matching_brace(source, open_index);
    &source[(open_index + 1)..close_index]
}

fn extract_arrow_block<'a>(source: &'a str, marker: &str) -> &'a str {
    let marker_index = source
        .find(marker)
        .unwrap_or_else(|| panic!("Missing marker: {}", marker));
    let arrow_index = source[marker_index..]
        .find("=> {")
        .map(|offset| marker_index + offset)
        .unwrap_or_else(|| panic!("Missing match-arm block after marker: {}", marker));
    let open_index = arrow_index + 3;
    let close_index = find_matching_brace(source, open_index);
    &source[(open_index + 1)..close_index]
}

fn contains_any(source: &str, needles: &[&str]) -> bool {
    needles.iter().any(|needle| source.contains(needle))
}

#[test]
fn phase_03_keyboard_lua_multi_key_is_down_returns_true_when_any_key_is_pressed() {
    let (state, lua) = make_vm();
    state.borrow_mut().keys_down.insert("space".to_string());

    lua.load(
        r#"
        assert(luna.keyboard.isDown("a", "space", "escape") == true)
        assert(luna.keyboard.isDown("a", "escape") == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn phase_03_keyboard_lua_key_repeat_toggle_round_trips() {
    let (_state, lua) = make_vm();

    lua.load(
        r#"
        assert(luna.keyboard.hasKeyRepeat() == false)
        luna.keyboard.setKeyRepeat(true)
        assert(luna.keyboard.hasKeyRepeat() == true)
        luna.keyboard.setKeyRepeat(false)
        assert(luna.keyboard.hasKeyRepeat() == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn phase_03_keyboard_lua_text_input_toggle_round_trips() {
    let (_state, lua) = make_vm();

    lua.load(
        r#"
        assert(luna.keyboard.hasTextInput() == false)
        luna.keyboard.setTextInput(true)
        assert(luna.keyboard.hasTextInput() == true)
        luna.keyboard.setTextInput(false)
        assert(luna.keyboard.hasTextInput() == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn gamepad_lua_get_count_empty() {
    let (_state, lua) = make_vm();
    lua.load("assert(luna.gamepad.getCount() == 0)")
        .exec()
        .unwrap();
}

#[test]
fn gamepad_lua_is_connected() {
    let (state, lua) = make_vm();
    state.borrow_mut().gamepads.push(GamepadState::new(0));
    lua.load(
        r#"
        assert(luna.gamepad.isConnected(0) == true)
        assert(luna.gamepad.isConnected(1) == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn gamepad_lua_is_down() {
    let (state, lua) = make_vm();
    let mut gp = GamepadState::new(0);
    gp.update_button(0, true);
    state.borrow_mut().gamepads.push(gp);
    lua.load(
        r#"
        assert(luna.gamepad.isDown(0, 0) == true)
        assert(luna.gamepad.isDown(0, 1) == false)
        assert(luna.gamepad.isDown(5, 0) == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn gamepad_lua_get_axis() {
    let (state, lua) = make_vm();
    let mut gp = GamepadState::new(0);
    gp.update_axis(1, -0.5);
    state.borrow_mut().gamepads.push(gp);
    lua.load(
        r#"
        local v = luna.gamepad.getAxis(0, 1)
        assert(math.abs(v - (-0.5)) < 0.001)
        local zero = luna.gamepad.getAxis(0, 99)
        assert(math.abs(zero) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn phase_03_gamepad_lua_inventory_and_metadata_contract() {
    let (state, lua) = make_vm();

    let mut connected = GamepadState::new(0);
    connected.name = "Pad Zero".to_string();
    connected.update_button(0, true);
    connected.update_axis(1, 0.25);

    let mut disconnected = GamepadState::new(1);
    disconnected.name = "Pad One".to_string();
    disconnected.connected = false;

    let mut st = state.borrow_mut();
    st.gamepads.push(connected);
    st.gamepads.push(disconnected);
    drop(st);

    lua.load(
        r#"
        assert(luna.gamepad.getCount() == 2)
        assert(luna.gamepad.getJoystickCount() == 2)

        local ids = luna.gamepad.getJoysticks()
        assert(type(ids) == "table")
        assert(#ids == 1)
        assert(ids[1] == 0)

        assert(luna.gamepad.isConnected(0) == true)
        assert(luna.gamepad.isConnected(1) == false)
        assert(luna.gamepad.isGamepad(0) == true)
        assert(luna.gamepad.isGamepad(1) == false)
        assert(luna.gamepad.getName(0) == "Pad Zero")
        assert(luna.gamepad.getButtonCount(0) == 1)
        assert(luna.gamepad.getAxisCount(0) == 1)
        assert(luna.gamepad.isDown(0, 0) == true)
        assert(math.abs(luna.gamepad.getAxis(0, 1) - 0.25) < 0.001)
        assert(luna.gamepad.isVibrationSupported(0) == false)
        "#,
    )
    .exec()
    .unwrap();
}

// ── Mouse state tests ──────────────────────────────────────────────

#[test]
fn mouse_default_state() {
    let ms = MouseState::new();
    assert!((ms.x - 0.0).abs() < 1e-5);
    assert!((ms.y - 0.0).abs() < 1e-5);
    assert!(ms.visible);
    assert!(!ms.grabbed);
    assert!(!ms.relative_mode);
    assert!((ms.scroll_x - 0.0).abs() < 1e-5);
    assert!((ms.scroll_y - 0.0).abs() < 1e-5);
    assert_eq!(ms.cursor_type, SystemCursor::Arrow);
}

#[test]
fn mouse_five_buttons() {
    let mut ms = MouseState::new();
    for i in 0..5 {
        ms.set_button(i, true);
        assert!(ms.is_down(i));
    }
    // Out of range is ignored
    ms.set_button(5, true);
    assert!(!ms.is_down(5));
}

#[test]
fn mouse_pressed_released_flags() {
    let mut ms = MouseState::new();
    ms.begin_frame();
    ms.set_button(3, true);
    assert!(ms.buttons_pressed[3]);
    ms.begin_frame();
    assert!(!ms.buttons_pressed[3]);
    ms.set_button(3, false);
    assert!(ms.buttons_released[3]);
}

#[test]
fn mouse_scroll_accumulation() {
    let mut ms = MouseState::new();
    ms.accumulate_scroll(1.0, 2.0);
    ms.accumulate_scroll(0.5, -1.0);
    let (sx, sy) = ms.get_scroll();
    assert!((sx - 1.5).abs() < 1e-5);
    assert!((sy - 1.0).abs() < 1e-5);
    ms.begin_frame();
    let (sx2, sy2) = ms.get_scroll();
    assert!((sx2 - 0.0).abs() < 1e-5);
    assert!((sy2 - 0.0).abs() < 1e-5);
}

#[test]
fn mouse_visibility_and_grab() {
    let mut ms = MouseState::new();
    assert!(ms.is_visible());
    ms.set_visible(false);
    assert!(!ms.is_visible());
    assert!(!ms.is_grabbed());
    ms.set_grabbed(true);
    assert!(ms.is_grabbed());
}

#[test]
fn mouse_relative_mode() {
    let mut ms = MouseState::new();
    assert!(!ms.get_relative_mode());
    ms.set_relative_mode(true);
    assert!(ms.get_relative_mode());
}

#[test]
fn mouse_system_cursor() {
    let mut ms = MouseState::new();
    ms.set_cursor(SystemCursor::Hand);
    assert_eq!(ms.get_cursor(), SystemCursor::Hand);
    assert_eq!(ms.get_cursor().as_str(), "hand");
}

#[test]
fn system_cursor_from_name() {
    assert_eq!(
        SystemCursor::from_name("crosshair"),
        SystemCursor::Crosshair
    );
    assert_eq!(SystemCursor::from_name("unknown"), SystemCursor::Arrow);
}

// ── Mouse Lua API tests ───────────────────────────────────────────

#[test]
fn mouse_lua_get_position() {
    let (state, lua) = make_vm();
    state.borrow_mut().mouse.x = 100.0;
    state.borrow_mut().mouse.y = 200.0;
    lua.load(
        r#"
        local x, y = luna.mouse.getPosition()
        assert(math.abs(x - 100) < 0.01)
        assert(math.abs(y - 200) < 0.01)
        assert(math.abs(luna.mouse.getX() - 100) < 0.01)
        assert(math.abs(luna.mouse.getY() - 200) < 0.01)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn mouse_lua_is_down_five_buttons() {
    let (state, lua) = make_vm();
    state.borrow_mut().mouse.buttons[3] = true; // back button
    lua.load(
        r#"
        assert(luna.mouse.isDown(4) == true)
        assert(luna.mouse.isDown(1) == false)
        assert(luna.mouse.isDown(5) == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn mouse_lua_visibility() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        assert(luna.mouse.isVisible() == true)
        luna.mouse.setVisible(false)
        assert(luna.mouse.isVisible() == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn mouse_lua_grabbed() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        assert(luna.mouse.isGrabbed() == false)
        luna.mouse.setGrabbed(true)
        assert(luna.mouse.isGrabbed() == true)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn mouse_lua_relative_mode() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        assert(luna.mouse.getRelativeMode() == false)
        luna.mouse.setRelativeMode(true)
        assert(luna.mouse.getRelativeMode() == true)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn mouse_lua_cursor() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        assert(luna.mouse.getCursor() == "arrow")
        luna.mouse.setCursor("hand")
        assert(luna.mouse.getCursor() == "hand")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn mouse_lua_wheel_delta() {
    let (state, lua) = make_vm();
    state.borrow_mut().mouse.accumulate_scroll(0.0, 3.0);
    lua.load(
        r#"
        local dx, dy = luna.mouse.getWheelDelta()
        assert(math.abs(dx) < 0.01)
        assert(math.abs(dy - 3.0) < 0.01)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn mouse_lua_set_position() {
    let (state, lua) = make_vm();
    lua.load("luna.mouse.setPosition(50, 75)").exec().unwrap();
    let st = state.borrow();
    assert!((st.mouse.x - 50.0).abs() < 1e-5);
    assert!((st.mouse.y - 75.0).abs() < 1e-5);
}

// ── Touch state tests ─────────────────────────────────────────────

#[test]
fn touch_default_empty() {
    let ts = TouchState::new();
    assert_eq!(ts.get_touch_count(), 0);
    assert!(ts.get_touches().is_empty());
    assert!(ts.get_touch(0).is_none());
}

#[test]
fn touch_start_move_end() {
    let mut ts = TouchState::new();
    ts.touch_start(1, 100.0, 200.0, 0.5);
    assert_eq!(ts.get_touch_count(), 1);
    let tp = ts.get_touch(1).unwrap();
    assert!((tp.x - 100.0).abs() < 1e-5);
    assert!((tp.y - 200.0).abs() < 1e-5);
    assert!((tp.pressure - 0.5).abs() < 1e-5);

    ts.touch_move(1, 150.0, 250.0, 0.8);
    let tp = ts.get_touch(1).unwrap();
    assert!((tp.x - 150.0).abs() < 1e-5);
    assert!((tp.y - 250.0).abs() < 1e-5);
    assert!((tp.pressure - 0.8).abs() < 1e-5);

    ts.touch_end(1);
    assert_eq!(ts.get_touch_count(), 0);
    assert!(ts.get_touch(1).is_none());
}

#[test]
fn touch_multiple_simultaneous() {
    let mut ts = TouchState::new();
    ts.touch_start(1, 10.0, 20.0, 1.0);
    ts.touch_start(2, 30.0, 40.0, 0.7);
    ts.touch_start(3, 50.0, 60.0, 0.3);
    assert_eq!(ts.get_touch_count(), 3);

    ts.touch_end(2);
    assert_eq!(ts.get_touch_count(), 2);
    assert!(ts.get_touch(2).is_none());
    assert!(ts.get_touch(1).is_some());
    assert!(ts.get_touch(3).is_some());
}

#[test]
fn touch_move_nonexistent_ignored() {
    let mut ts = TouchState::new();
    ts.touch_move(99, 10.0, 20.0, 1.0);
    assert_eq!(ts.get_touch_count(), 0);
}

// ── Touch Lua API tests ──────────────────────────────────────────

#[test]
fn touch_lua_get_touch_count() {
    let (state, lua) = make_vm();
    lua.load("assert(luna.touch.getTouchCount() == 0)")
        .exec()
        .unwrap();
    state.borrow_mut().touch.touch_start(1, 10.0, 20.0, 1.0);
    lua.load("assert(luna.touch.getTouchCount() == 1)")
        .exec()
        .unwrap();
}

#[test]
fn touch_lua_get_position() {
    let (state, lua) = make_vm();
    state.borrow_mut().touch.touch_start(42, 123.0, 456.0, 0.9);
    lua.load(
        r#"
        local x, y = luna.touch.getPosition(42)
        assert(math.abs(x - 123.0) < 0.01)
        assert(math.abs(y - 456.0) < 0.01)
        -- nonexistent touch returns 0,0
        local nx, ny = luna.touch.getPosition(999)
        assert(math.abs(nx) < 0.01)
        assert(math.abs(ny) < 0.01)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn touch_lua_get_pressure() {
    let (state, lua) = make_vm();
    state.borrow_mut().touch.touch_start(7, 50.0, 60.0, 0.75);
    lua.load(
        r#"
        local p = luna.touch.getPressure(7)
        assert(math.abs(p - 0.75) < 0.01)
        -- nonexistent returns 0
        local p2 = luna.touch.getPressure(999)
        assert(math.abs(p2) < 0.01)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn touch_lua_get_touches() {
    let (state, lua) = make_vm();
    state.borrow_mut().touch.touch_start(1, 10.0, 20.0, 0.5);
    state.borrow_mut().touch.touch_start(2, 30.0, 40.0, 1.0);
    lua.load(
        r#"
        local touches = luna.touch.getTouches()
        assert(#touches == 2)
        local by_id = {}
        for _, t in ipairs(touches) do
            assert(t.id ~= nil)
            assert(t.x ~= nil)
            assert(t.y ~= nil)
            assert(t.pressure ~= nil)
            by_id[t.id] = t
        end

        assert(by_id[1] ~= nil)
        assert(math.abs(by_id[1].x - 10.0) < 0.01)
        assert(math.abs(by_id[1].y - 20.0) < 0.01)
        assert(math.abs(by_id[1].pressure - 0.5) < 0.01)

        assert(by_id[2] ~= nil)
        assert(math.abs(by_id[2].x - 30.0) < 0.01)
        assert(math.abs(by_id[2].y - 40.0) < 0.01)
        assert(math.abs(by_id[2].pressure - 1.0) < 0.01)
        "#,
    )
    .exec()
    .unwrap();
}

// ── Phase 03 source-contract tests ───────────────────────────────

#[test]
fn phase_03_keyboard_runtime_keypressed_callback_uses_key_scancode_and_repeat() {
    let app_source = read_source("src/engine/app.rs");
    let keyboard_input_block =
        extract_arrow_block(&app_source, "WindowEvent::KeyboardInput { event, .. } =>");

    assert!(keyboard_input_block.contains("\"keypressed\""));
    assert!(keyboard_input_block.contains("key_str.clone(), sc.clone(), event.repeat"));
}

#[test]
fn phase_03_keyboard_runtime_keyreleased_is_not_guarded_by_prev_key_state() {
    let app_source = read_source("src/engine/app.rs");
    let keyboard_input_block =
        extract_arrow_block(&app_source, "WindowEvent::KeyboardInput { event, .. } =>");

    assert!(keyboard_input_block.contains("\"keyreleased\""));
    assert!(keyboard_input_block.contains("(key_str.clone(), sc)"));
    assert!(
        !keyboard_input_block.contains("!self.prev_keys.contains(&key_str)"),
        "keyreleased delivery is still guarded by prev_keys state instead of firing on actual release"
    );
}

#[test]
fn phase_03_textinput_runtime_only_invokes_lua_callback_when_text_input_enabled() {
    let app_source = read_source("src/engine/app.rs");
    let ime_block = extract_braced_block(
        &app_source,
        "WindowEvent::Ime(winit::event::Ime::Commit(text)) =>",
    );
    let enabled_block = extract_braced_block(ime_block, "if st.keyboard.has_text_input()");

    assert!(enabled_block.contains("push_text_input(text.clone())"));
    assert!(
        enabled_block.contains("call_lua_callback(lua, \"textinput\", text);"),
        "textinput callback is still dispatched outside the has_text_input gate"
    );
}

#[test]
fn phase_03_mouse_runtime_applies_cursor_state_to_window_backend() {
    let app_source = read_source("src/engine/app.rs");

    assert!(
        app_source.contains("set_cursor_visible"),
        "mouse visibility changes are not yet applied to the winit window backend"
    );
    assert!(
        app_source.contains("set_cursor_grab"),
        "mouse grab/relative-mode changes are not yet applied to the winit window backend"
    );
    assert!(
        app_source.contains("set_cursor_position"),
        "mouse setPosition requests are not yet applied to the winit window backend"
    );
    assert!(
        contains_any(&app_source, &["set_cursor(", "set_cursor_icon("]),
        "mouse cursor type changes are not yet applied to the winit window backend"
    );
}

#[test]
fn phase_03_gamepad_runtime_dispatches_button_axis_and_hotplug_callbacks() {
    let app_source = read_source("src/engine/app.rs");

    for callback_name in [
        "gamepadpressed",
        "gamepadreleased",
        "gamepadaxis",
        "joystickadded",
        "joystickremoved",
    ] {
        assert!(
            app_source.contains(callback_name),
            "Missing runtime dispatch for luna.{} callback",
            callback_name
        );
    }
}

#[test]
fn phase_03_touch_runtime_dispatches_six_argument_callbacks() {
    let app_source = read_source("src/engine/app.rs");
    let touch_block = extract_braced_block(&app_source, "WindowEvent::Touch(touch) =>");

    assert!(
        touch_block
            .contains("call_lua_callback(lua, \"touchpressed\", (id, x, y, dx, dy, pressure));"),
        "touchpressed still lacks dx/dy arguments"
    );
    assert!(
        touch_block
            .contains("call_lua_callback(lua, \"touchmoved\", (id, x, y, dx, dy, pressure));"),
        "touchmoved still lacks dx/dy arguments"
    );
    assert!(
        touch_block
            .contains("call_lua_callback(lua, \"touchreleased\", (id, x, y, dx, dy, pressure));"),
        "touchreleased still lacks dx/dy arguments"
    );
}
