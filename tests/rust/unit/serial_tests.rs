//! Integration tests for the serial module.

use luna2d::serial::{from_json, to_json, from_toml, to_toml, from_csv, to_csv};
use luna2d::serial::{CsvOptions, SerialValue};

// ── JSON ─────────────────────────────────────────────────────────────────────

#[test]
fn serial_json_roundtrip_basic_types() {
    let json = r#"{"name":"Luna2D","version":4,"pi":3.14,"enabled":true}"#;
    let val = from_json(json).unwrap();
    let out = to_json(&val, false).unwrap();
    let val2 = from_json(&out).unwrap();
    if let SerialValue::Map(map) = &val2 {
        if let Some(SerialValue::Str(s)) = map.get("name") { assert_eq!(s, "Luna2D"); }
        if let Some(SerialValue::Int(n)) = map.get("version") { assert_eq!(*n, 4); }
    } else {
        panic!("expected Map");
    }
}

#[test]
fn serial_json_array_roundtrip() {
    let json = "[1, 2, 3]";
    let val = from_json(json).unwrap();
    let out = to_json(&val, false).unwrap();
    assert!(out.contains("1"));
    assert!(out.contains("2"));
    assert!(out.contains("3"));
}

#[test]
fn serial_json_null() {
    let val = from_json("null").unwrap();
    matches!(val, SerialValue::Null);
    let out = to_json(&val, false).unwrap();
    assert_eq!(out, "null");
}

#[test]
fn serial_json_error_on_bad_input() {
    let result = from_json("{bad json}");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("JSON parse error"));
}

#[test]
fn serial_json_pretty() {
    let json = r#"{"a":1}"#;
    let val = from_json(json).unwrap();
    let pretty = to_json(&val, true).unwrap();
    assert!(pretty.contains('\n'));
}

// ── TOML ─────────────────────────────────────────────────────────────────────

#[test]
fn serial_toml_basic_types() {
    let input = r#"
name = "Luna2D"
version = 4
pi = 3.14
enabled = true
"#;
    let val = from_toml(input).unwrap();
    if let SerialValue::Map(map) = &val {
        if let Some(SerialValue::Str(s)) = map.get("name") { assert_eq!(s, "Luna2D"); }
        if let Some(SerialValue::Int(n)) = map.get("version") { assert_eq!(*n, 4); }
        if let Some(SerialValue::Bool(b)) = map.get("enabled") { assert!(*b); }
    } else {
        panic!("expected Map");
    }
}

#[test]
fn serial_toml_nested_table() {
    let input = r#"
[window]
width = 800
height = 600
title = "test"
"#;
    let val = from_toml(input).unwrap();
    if let SerialValue::Map(map) = &val {
        if let Some(SerialValue::Map(win)) = map.get("window") {
            if let Some(SerialValue::Int(w)) = win.get("width") { assert_eq!(*w, 800); }
        }
    }
}

#[test]
fn serial_toml_roundtrip() {
    let input = r#"title = "game"
debug = true
"#;
    let val = from_toml(input).unwrap();
    let encoded = to_toml(&val).unwrap();
    assert!(encoded.contains("title = \"game\""));
    assert!(encoded.contains("debug = true"));
}

#[test]
fn serial_toml_parse_error() {
    let result = from_toml("invalid = [");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("TOML parse error"));
}

// ── CSV ──────────────────────────────────────────────────────────────────────

#[test]
fn serial_csv_parse_with_headers() {
    let input = "name,age\nAlice,30\nBob,25";
    let val = from_csv(input, CsvOptions { delimiter: b',', has_headers: true }).unwrap();
    if let SerialValue::Seq(rows) = &val {
        assert_eq!(rows.len(), 2);
        if let SerialValue::Map(row) = &rows[0] {
            if let Some(SerialValue::Str(name)) = row.get("name") { assert_eq!(name, "Alice"); }
            if let Some(SerialValue::Str(age)) = row.get("age") { assert_eq!(age, "30"); }
        }
    } else {
        panic!("expected Seq");
    }
}

#[test]
fn serial_csv_roundtrip() {
    let input = "a,b\n1,2\n3,4";
    let val = from_csv(input, CsvOptions::default()).unwrap();
    let out = to_csv(&val, CsvOptions::default()).unwrap();
    // Should contain the data
    assert!(out.contains("a,b") || out.contains("a") && out.contains("b"));
    assert!(out.contains("1") && out.contains("2"));
}

// YAML removed: design-assumption B-05 (use TOML for human-authored config).

// ── Lua integration tests ─────────────────────────────────────────────────────

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::lua_api::{create_lua_vm, SharedState};
use luna2d::engine::config::Config;

fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone(), &Config::default().modules).unwrap();
    (state, lua)
}

#[test]
fn test_lua_serial_fromjson_basic() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local t = luna.serial.fromJson('{"name":"hello","count":42}')
        assert(t.name == "hello")
        assert(t.count == 42)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_serial_tojson_basic() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local result = luna.serial.toJson({ name = "test", count = 5 })
        assert(type(result) == "string")
        assert(string.find(result, '"name"') or string.find(result, 'name'))
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_serial_fromtoml_basic() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local t = luna.serial.fromToml('name = "hello"\ncount = 42\nactive = true')
        assert(t.name == "hello")
        assert(t.count == 42)
        assert(t.active == true)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_serial_totoml_basic() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local result = luna.serial.toToml({ name = "test", count = 5 })
        assert(type(result) == "string")
        assert(string.find(result, 'name = "test"'))
        assert(string.find(result, "count = 5"))
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_serial_fromjson_error() {
    let (_state, lua) = make_vm();
    let result = lua
        .load(r#"luna.serial.fromJson("{bad json}")"#)
        .exec();
    assert!(result.is_err());
}
