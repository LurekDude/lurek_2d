//! INTERNAL ONLY: public serial behavior is covered by the Lua-first suites in
//! `tests/lua/unit/test_serial_unit.lua` and `tests/lua/golden/test_serial_golden.lua`.
//!
//! The Rust-only coverage that remains here is the low-level `SerialValue` <->
//! `LuaValue` bridge used by the binding layer itself.

// ── lua_table ─────────────────────────────────────────────────────────────────

mod lua_table_tests {
    use lurek2d::serial::lua_table::{from_lua, to_lua, SerialValue};
    use indexmap::IndexMap;
    use mlua::prelude::*;

    #[test]
    fn to_lua_null_becomes_nil() {
        let lua = Lua::new();
        let val = to_lua(&lua, &SerialValue::Null).unwrap();
        assert!(matches!(val, LuaValue::Nil));
    }

    #[test]
    fn to_lua_bool_preserved() {
        let lua = Lua::new();
        let val = to_lua(&lua, &SerialValue::Bool(true)).unwrap();
        assert!(matches!(val, LuaValue::Boolean(true)));
    }

    #[test]
    fn to_lua_int_preserved() {
        let lua = Lua::new();
        let val = to_lua(&lua, &SerialValue::Int(42)).unwrap();
        assert!(matches!(val, LuaValue::Integer(42)));
    }

    #[test]
    fn to_lua_float_preserved() {
        let lua = Lua::new();
        let val = to_lua(&lua, &SerialValue::Float(3.14)).unwrap();
        match val {
            LuaValue::Number(n) => assert!((n - 3.14).abs() < 1e-10),
            other => panic!("expected Number, got {:?}", other),
        }
    }

    #[test]
    fn to_lua_string_preserved() {
        let lua = Lua::new();
        let val = to_lua(&lua, &SerialValue::Str("hello".to_string())).unwrap();
        match val {
            LuaValue::String(s) => assert_eq!(s.to_str().unwrap(), "hello"),
            other => panic!("expected String, got {:?}", other),
        }
    }

    #[test]
    fn round_trip_seq() {
        let lua = Lua::new();
        let original = SerialValue::Seq(vec![
            SerialValue::Int(1),
            SerialValue::Int(2),
            SerialValue::Int(3),
        ]);
        let lua_val = to_lua(&lua, &original).unwrap();
        let back = from_lua(&lua_val).unwrap();
        match back {
            SerialValue::Seq(v) => {
                assert_eq!(v.len(), 3);
                assert!(matches!(v[0], SerialValue::Int(1)));
            }
            other => panic!("expected Seq, got {:?}", other),
        }
    }

    #[test]
    fn round_trip_map() {
        let lua = Lua::new();
        let mut map = IndexMap::new();
        map.insert("key".to_string(), SerialValue::Str("val".to_string()));
        let original = SerialValue::Map(map);
        let lua_val = to_lua(&lua, &original).unwrap();
        let back = from_lua(&lua_val).unwrap();
        match back {
            SerialValue::Map(m) => {
                assert!(matches!(m.get("key"), Some(SerialValue::Str(s)) if s == "val"));
            }
            other => panic!("expected Map, got {:?}", other),
        }
    }

    #[test]
    fn from_lua_whole_number_coerces_to_int() {
        // Lua Number 5.0 with zero fractional part should coerce to Int(5)
        let val = LuaValue::Number(5.0);
        let sv = from_lua(&val).unwrap();
        assert!(matches!(sv, SerialValue::Int(5)));
    }

    #[test]
    fn from_lua_fractional_number_stays_float() {
        let val = LuaValue::Number(3.14);
        let sv = from_lua(&val).unwrap();
        match sv {
            SerialValue::Float(f) => assert!((f - 3.14).abs() < 1e-10),
            other => panic!("expected Float, got {:?}", other),
        }
    }

    #[test]
    fn from_lua_rejects_unsupported_types() {
        let lua = Lua::new();
        let func = lua.create_function(|_, ()| Ok(())).unwrap();
        let val = LuaValue::Function(func);
        assert!(from_lua(&val).is_err());
    }
}

mod codec_tests {
    use lurek2d::serial::{
        decode_bytes, decode_text, detect_format, encode, from_csv_reader, DecodeOptions,
        EncodeOptions, EncodedValue, SerialFormat, SerialValue,
    };
    use std::io::Cursor;

    #[test]
    fn detect_format_finds_json() {
        assert_eq!(detect_format("{\"name\":\"hero\"}"), Some(SerialFormat::Json));
    }

    #[test]
    fn detect_format_finds_toml() {
        assert_eq!(detect_format("title = \"demo\""), Some(SerialFormat::Toml));
    }

    #[test]
    fn decode_text_auto_json() {
        let val = decode_text("{\"hp\":10}", None, DecodeOptions::default()).unwrap();
        match val {
            SerialValue::Map(m) => assert!(matches!(m.get("hp"), Some(SerialValue::Int(10)))),
            other => panic!("expected map, got {other:?}"),
        }
    }

    #[test]
    fn encode_decode_msgpack_round_trip() {
        let src = SerialValue::Seq(vec![SerialValue::Int(1), SerialValue::Int(2)]);
        let bytes = match encode(&src, SerialFormat::MsgPack, EncodeOptions::default()).unwrap() {
            EncodedValue::Binary(b) => b,
            EncodedValue::Text(_) => panic!("expected binary output"),
        };
        let back = decode_bytes(&bytes, SerialFormat::MsgPack).unwrap();
        match back {
            SerialValue::Seq(items) => assert_eq!(items.len(), 2),
            other => panic!("expected seq, got {other:?}"),
        }
    }

    #[test]
    fn from_csv_reader_parses_rows() {
        let data = Cursor::new("name,score\nalice,10\n");
        let val = from_csv_reader(data, Default::default()).unwrap();
        match val {
            SerialValue::Seq(rows) => assert_eq!(rows.len(), 1),
            other => panic!("expected seq, got {other:?}"),
        }
    }

    #[test]
    fn decode_text_ini_returns_section_map() {
        let val = decode_text("[player]\nname=hero\n", Some(SerialFormat::Ini), DecodeOptions::default()).unwrap();
        match val {
            SerialValue::Map(root) => {
                assert!(matches!(root.get("player"), Some(SerialValue::Map(_))));
            }
            other => panic!("expected map, got {other:?}"),
        }
    }
}

mod schema_defaults_tests {
    use indexmap::IndexMap;
    use lurek2d::serial::{apply_schema_defaults, SerialValue};

    #[test]
    fn apply_defaults_fills_missing_fields() {
        let value = SerialValue::Map(IndexMap::new());

        let mut hp_schema = IndexMap::new();
        hp_schema.insert("type".to_string(), SerialValue::Str("number".to_string()));
        hp_schema.insert("default".to_string(), SerialValue::Int(100));

        let mut fields = IndexMap::new();
        fields.insert("hp".to_string(), SerialValue::Map(hp_schema));

        let mut schema = IndexMap::new();
        schema.insert("type".to_string(), SerialValue::Str("table".to_string()));
        schema.insert("fields".to_string(), SerialValue::Map(fields));

        let patched = apply_schema_defaults(&value, &SerialValue::Map(schema)).unwrap();
        match patched {
            SerialValue::Map(m) => assert!(matches!(m.get("hp"), Some(SerialValue::Int(100)))),
            other => panic!("expected map, got {other:?}"),
        }
    }
}
