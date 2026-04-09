//! Integration tests for the binary module.

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use lurek2d::data::byte_data::ByteData;
use lurek2d::data::compress::{compress, decompress, CompressFormat};
use lurek2d::data::encode::{decode, encode, EncodeFormat};
use lurek2d::data::hash::{hash, HashAlgorithm};
use lurek2d::data::toml_convert;
use lurek2d::engine::config::Config;
use lurek2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state, &Config::default().modules).expect("Failed to create Lua VM")
}

#[test]
fn byte_data_new_zeroed() {
    let data = ByteData::new(10);
    assert_eq!(data.len(), 10);
    for i in 0..10 {
        assert_eq!(data.get_byte(i), Some(0));
    }
}

#[test]
fn byte_data_from_string() {
    let data = ByteData::from_string("hello");
    assert_eq!(data.len(), 5);
    assert_eq!(data.get_string(), "hello");
}

#[test]
fn byte_data_set_get() {
    let mut data = ByteData::new(4);
    assert!(data.set_byte(0, 65));
    assert!(data.set_byte(1, 66));
    assert_eq!(data.get_byte(0), Some(65));
    assert_eq!(data.get_byte(1), Some(66));
    assert!(!data.set_byte(10, 1)); // out of bounds
    assert_eq!(data.get_byte(10), None); // out of bounds
}

#[test]
fn byte_data_clone() {
    let original = ByteData::from_string("test");
    let cloned = original.clone_data();
    assert_eq!(cloned.get_string(), "test");
    assert_eq!(cloned.len(), 4);
}

#[test]
fn compress_decompress_deflate() {
    let original = b"Hello, Lurek2D! This is a test of deflate compression.";
    let compressed = compress(original, CompressFormat::Deflate, 6).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Deflate).unwrap();
    assert_eq!(decompressed, original);
}

#[test]
fn compress_decompress_gzip() {
    let original = b"Hello, Lurek2D! This is a test of gzip compression.";
    let compressed = compress(original, CompressFormat::Gzip, 6).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Gzip).unwrap();
    assert_eq!(decompressed, original);
}

#[test]
fn compress_decompress_zlib() {
    let original = b"Hello, Lurek2D! This is a test of zlib compression.";
    let compressed = compress(original, CompressFormat::Zlib, 6).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Zlib).unwrap();
    assert_eq!(decompressed, original);
}

#[test]
fn compress_decompress_lz4() {
    let original = b"Hello, Lurek2D! This is a test of LZ4 compression.";
    let compressed = compress(original, CompressFormat::Lz4, 0).unwrap();
    let decompressed = decompress(&compressed, CompressFormat::Lz4).unwrap();
    assert_eq!(decompressed, original);
}

#[test]
fn hash_md5_known() {
    let result = hash(HashAlgorithm::Md5, b"hello");
    assert_eq!(result, "5d41402abc4b2a76b9719d911017c592");
}

#[test]
fn hash_sha256_known() {
    let result = hash(HashAlgorithm::Sha256, b"hello");
    assert_eq!(
        result,
        "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
    );
}

#[test]
fn hash_sha512_known() {
    let result = hash(HashAlgorithm::Sha512, b"hello");
    assert_eq!(
        result,
        "9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043"
    );
}

#[test]
fn hash_sha1_known() {
    let result = hash(HashAlgorithm::Sha1, b"hello");
    assert_eq!(result, "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d");
}

#[test]
fn encode_decode_base64() {
    let original = b"Hello, Lurek2D!";
    let encoded = encode(EncodeFormat::Base64, original);
    assert_eq!(encoded, "SGVsbG8sIEx1bmEyRCE=");
    let decoded = decode(EncodeFormat::Base64, &encoded).unwrap();
    assert_eq!(decoded, original);
}

#[test]
fn encode_decode_hex() {
    let original = b"Hello";
    let encoded = encode(EncodeFormat::Hex, original);
    assert_eq!(encoded, "48656c6c6f");
    let decoded = decode(EncodeFormat::Hex, &encoded).unwrap();
    assert_eq!(decoded, original);
}

// ── DataView tests ───────────────────────────────────────────────────────────

use lurek2d::data::DataView;

#[test]
fn data_dataview_reads_bytes() {
    use std::sync::Arc;
    let bytes = Arc::new(vec![0xABu8, 0xCD, 0xEF, 0x01]);
    let dv = DataView::new(bytes);
    assert_eq!(dv.get_u8(0).unwrap(), 0xAB);
    assert_eq!(dv.get_u8(1).unwrap(), 0xCD);
    assert_eq!(dv.get_u8(3).unwrap(), 0x01);
    assert_eq!(dv.get_size(), 4);
}

#[test]
fn data_dataview_slice() {
    use std::sync::Arc;
    let bytes = Arc::new(vec![0u8, 0, 0x01, 0x02, 0, 0]);
    let dv = DataView::new_slice(bytes, 2, 2).unwrap();
    assert_eq!(dv.get_size(), 2);
    assert_eq!(dv.get_u8(0).unwrap(), 0x01);
    assert_eq!(dv.get_u8(1).unwrap(), 0x02);
    assert!(dv.get_u8(2).is_err());
}

#[test]
fn data_dataview_u16_read() {
    use std::sync::Arc;
    let bytes = Arc::new(vec![0x02u8, 0x01]);
    let dv = DataView::new(bytes);
    assert_eq!(dv.get_u16(0).unwrap(), 0x0102);
}

#[test]
fn data_dataview_out_of_bounds_error() {
    use std::sync::Arc;
    let bytes = Arc::new(vec![0u8; 2]);
    let dv = DataView::new(bytes);
    assert!(dv.get_u32(0).is_err());
}

// ── Lurek2D Binary Pack Format tests ──────────────────────────────────────────

use lurek2d::data::bin_pack::{measure_size, read, write, BinValue};

#[test]
fn binary_write_read_u32_f32_roundtrip() {
    let bd = write("u32 f32", &[BinValue::U32(42), BinValue::F32(3.14)]).unwrap();
    let (vals, pos) = read("u32 f32", bd.as_bytes(), 0).unwrap();
    assert_eq!(pos, 8);
    if let BinValue::U32(n) = vals[0] {
        assert_eq!(n, 42);
    } else {
        panic!("expected U32");
    }
    if let BinValue::F32(f) = vals[1] {
        assert!((f - 3.14f32).abs() < 1e-4);
    } else {
        panic!("expected F32");
    }
}

#[test]
fn binary_write_read_str_roundtrip() {
    let bd = write("str", &[BinValue::Str("hello".to_string())]).unwrap();
    let (vals, _) = read("str", bd.as_bytes(), 0).unwrap();
    if let BinValue::Str(s) = &vals[0] {
        assert_eq!(s, "hello");
    } else {
        panic!("expected Str");
    }
}

#[test]
fn binary_write_read_cstr_roundtrip() {
    let bd = write("cstr", &[BinValue::Str("world".to_string())]).unwrap();
    assert_eq!(bd.as_bytes().len(), 6);
    let (vals, _) = read("cstr", bd.as_bytes(), 0).unwrap();
    if let BinValue::Str(s) = &vals[0] {
        assert_eq!(s, "world");
    } else {
        panic!("expected Str");
    }
}

#[test]
fn binary_endian_big() {
    let bd = write("be u16", &[BinValue::U16(0x0102)]).unwrap();
    let bytes = bd.as_bytes();
    assert_eq!(bytes[0], 0x01);
    assert_eq!(bytes[1], 0x02);
}

#[test]
fn binary_endian_little() {
    let bd = write("le u16", &[BinValue::U16(0x0102)]).unwrap();
    let bytes = bd.as_bytes();
    assert_eq!(bytes[0], 0x02);
    assert_eq!(bytes[1], 0x01);
}

#[test]
fn binary_pad_byte() {
    let bd = write("pad u8", &[BinValue::U8(42)]).unwrap();
    assert_eq!(bd.as_bytes().len(), 2);
    assert_eq!(bd.as_bytes()[0], 0);
    assert_eq!(bd.as_bytes()[1], 42);
}

#[test]
fn binary_bool_roundtrip() {
    let bd = write("bool bool", &[BinValue::Bool(true), BinValue::Bool(false)]).unwrap();
    assert_eq!(bd.as_bytes(), &[1u8, 0u8]);
    let (vals, _) = read("bool bool", bd.as_bytes(), 0).unwrap();
    if let BinValue::Bool(b) = vals[0] {
        assert!(b);
    } else {
        panic!("expected Bool");
    }
    if let BinValue::Bool(b) = vals[1] {
        assert!(!b);
    } else {
        panic!("expected Bool");
    }
}

#[test]
fn binary_measure_size_fixed_types() {
    let sz = measure_size("u8 u16 u32 u64 i8 i16 i32 i64").unwrap();
    assert_eq!(sz, 30);
    let sz = measure_size("f32 f64 bool pad").unwrap();
    assert_eq!(sz, 14);
}

#[test]
fn binary_measure_size_errors_on_str() {
    assert!(measure_size("u32 str").is_err());
}

#[test]
fn binary_measure_size_errors_on_cstr() {
    assert!(measure_size("cstr").is_err());
}

#[test]
fn binary_unknown_token_error() {
    assert!(write("unknown", &[]).is_err());
    assert!(read("badtoken", &[], 0).is_err());
    assert!(measure_size("<fI>").is_err());
}

#[test]
fn binary_multi_type_roundtrip() {
    let vals = &[BinValue::I8(-1), BinValue::U8(255), BinValue::F64(1.5)];
    let bd = write("le i8 u8 f64", vals).unwrap();
    let (out, pos) = read("le i8 u8 f64", bd.as_bytes(), 0).unwrap();
    assert_eq!(pos, bd.as_bytes().len());
    if let BinValue::I8(v) = out[0] {
        assert_eq!(v, -1);
    } else {
        panic!("expected I8");
    }
    if let BinValue::U8(v) = out[1] {
        assert_eq!(v, 255);
    } else {
        panic!("expected U8");
    }
    if let BinValue::F64(v) = out[2] {
        assert!((v - 1.5).abs() < 1e-10);
    } else {
        panic!("expected F64");
    }
}

#[test]
fn binary_offset_read() {
    let bd = write(
        "u8 u8 u8",
        &[BinValue::U8(10), BinValue::U8(20), BinValue::U8(30)],
    )
    .unwrap();
    let (vals, pos) = read("u8 u8", bd.as_bytes(), 1).unwrap();
    assert_eq!(pos, 3);
    if let BinValue::U8(v) = vals[0] {
        assert_eq!(v, 20);
    } else {
        panic!();
    }
    if let BinValue::U8(v) = vals[1] {
        assert_eq!(v, 30);
    } else {
        panic!();
    }
}

#[test]
fn binary_dataview_from_write() {
    use std::sync::Arc;
    let bd = write("le f32", &[BinValue::F32(2.5f32)]).unwrap();
    let bytes = Arc::new(bd.as_bytes().to_vec());
    let dv = DataView::new(bytes);
    let v = dv.get_f32(0).unwrap();
    assert!((v - 2.5f32).abs() < 1e-6);
}

// ── Merged from data_tests2.rs ────────────────────────────────────────────

use lurek2d::data::pack::{get_packed_size, pack, unpack, PackValue};

#[test]
fn toml_parse_basic_types() {
    let input = r#"
        name = "Lurek2D"
        version = 4
        pi = 3.14
        enabled = true
    "#;
    let val = toml_convert::parse_toml(input).unwrap();
    let t = val.as_table().unwrap();
    assert_eq!(t["name"].as_str(), Some("Lurek2D"));
    assert_eq!(t["version"].as_integer(), Some(4));
    assert!((t["pi"].as_float().unwrap() - 3.14).abs() < 1e-5);
    assert_eq!(t["enabled"].as_bool(), Some(true));
}

#[test]
fn toml_parse_nested_table() {
    let input = r#"
        [window]
        width = 800
        height = 600
        title = "test"
    "#;
    let val = toml_convert::parse_toml(input).unwrap();
    let t = val.as_table().unwrap();
    let window = t["window"].as_table().unwrap();
    assert_eq!(window["width"].as_integer(), Some(800));
    assert_eq!(window["height"].as_integer(), Some(600));
}

#[test]
fn toml_parse_array() {
    let input = r#"
        colors = ["red", "green", "blue"]
    "#;
    let val = toml_convert::parse_toml(input).unwrap();
    let t = val.as_table().unwrap();
    let colors = t["colors"].as_array().unwrap();
    assert_eq!(colors.len(), 3);
    assert_eq!(colors[0].as_str(), Some("red"));
}

#[test]
fn toml_encode_basic() {
    let mut map = toml::map::Map::new();
    map.insert("name".into(), toml::Value::String("Lurek2D".into()));
    map.insert("version".into(), toml::Value::Integer(4));
    let val = toml::Value::Table(map);
    let result = toml_convert::encode_toml(&val).unwrap();
    assert!(result.contains("name = \"Lurek2D\""));
    assert!(result.contains("version = 4"));
}

#[test]
fn toml_parse_error() {
    let result = toml_convert::parse_toml("invalid = [");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("TOML parse error"));
}

#[test]
fn lua_parse_toml_basic_returns_table() {
    let lua = make_vm();
    lua.load(
        r#"
        local t = luna.data.parseToml('name = "hello"\ncount = 42\nactive = true')
        assert(t.name == "hello")
        assert(t.count == 42)
        assert(t.active == true)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn lua_parse_toml_nested_returns_table() {
    let lua = make_vm();
    lua.load(
        r#"
        local toml_str = '[window]\nwidth = 800\nheight = 600\ntitle = "Lurek2D"'
        local t = luna.data.parseToml(toml_str)
        assert(t.window.width == 800)
        assert(t.window.height == 600)
        assert(t.window.title == "Lurek2D")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn lua_parse_toml_array_returns_seq() {
    let lua = make_vm();
    lua.load(
        r#"
        local t = luna.data.parseToml('items = [1, 2, 3]')
        assert(#t.items == 3)
        assert(t.items[1] == 1)
        assert(t.items[2] == 2)
        assert(t.items[3] == 3)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn lua_encode_toml_basic_returns_string() {
    let lua = make_vm();
    lua.load(
        r#"
        local result = luna.data.encodeToml({ name = "test", count = 5 })
        assert(type(result) == "string")
        assert(string.find(result, 'name = "test"'))
        assert(string.find(result, "count = 5"))
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn lua_toml_roundtrip_preserves_values() {
    let lua = make_vm();
    lua.load(
        r#"
        local original = { title = "game", debug = true }
        local encoded = luna.data.encodeToml(original)
        local decoded = luna.data.parseToml(encoded)
        assert(decoded.title == "game")
        assert(decoded.debug == true)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn lua_parse_toml_error_returns_lua_error() {
    let lua = make_vm();
    let result = lua
        .load(
            r#"
            luna.data.parseToml("invalid = [")
            "#,
        )
        .exec();
    assert!(result.is_err());
}

#[test]
fn data_pack_unpack_f32_round_trips() {
    let bd = pack("<f", &[PackValue::Float(3.14f32)]).unwrap();
    let (vals, _pos) = unpack("<f", bd.as_bytes(), 0).unwrap();
    if let PackValue::Float(v) = vals[0] {
        assert!((v - 3.14f32).abs() < 1e-4);
    } else {
        panic!("expected Float");
    }
}

#[test]
fn data_pack_unpack_u8_round_trips() {
    let bd = pack("B", &[PackValue::UInt(255)]).unwrap();
    let (vals, pos) = unpack("B", bd.as_bytes(), 0).unwrap();
    assert_eq!(pos, 1);
    if let PackValue::UInt(v) = vals[0] {
        assert_eq!(v, 255);
    } else {
        panic!("expected UInt");
    }
}

#[test]
fn data_pack_string_round_trips() {
    let bd = pack("s", &[PackValue::Str("hello".to_string())]).unwrap();
    let (vals, _) = unpack("s", bd.as_bytes(), 0).unwrap();
    if let PackValue::Str(s) = &vals[0] {
        assert_eq!(s, "hello");
    } else {
        panic!("expected Str");
    }
}

#[test]
fn data_pack_null_terminated_string_round_trips() {
    let bd = pack("z", &[PackValue::Str("world".to_string())]).unwrap();
    // Expect "world" + 0 = 6 bytes
    assert_eq!(bd.as_bytes().len(), 6);
    let (vals, _) = unpack("z", bd.as_bytes(), 0).unwrap();
    if let PackValue::Str(s) = &vals[0] {
        assert_eq!(s, "world");
    } else {
        panic!("expected Str");
    }
}

#[test]
fn data_getpackedsize_matches_pack_output() {
    let vals = &[PackValue::UInt(1u64), PackValue::Float(1.0f32)];
    let sz = get_packed_size("Bf", vals).unwrap();
    let bd = pack("Bf", vals).unwrap();
    assert_eq!(sz, bd.as_bytes().len());
}

#[test]
fn data_getpackedsize_fixed_types_no_values_needed() {
    // B=1, H=2, I=4, f=4 => total 11
    let sz = get_packed_size("BHIf", &[]).unwrap();
    assert_eq!(sz, 11);
}

#[test]
fn data_pack_endian_big() {
    let bd = pack(">H", &[PackValue::UInt(0x0102)]).unwrap();
    let bytes = bd.as_bytes();
    assert_eq!(bytes[0], 0x01);
    assert_eq!(bytes[1], 0x02);
}

#[test]
fn data_pack_endian_little() {
    let bd = pack("<H", &[PackValue::UInt(0x0102)]).unwrap();
    let bytes = bd.as_bytes();
    assert_eq!(bytes[0], 0x02);
    assert_eq!(bytes[1], 0x01);
}

#[test]
fn data_pack_padding_byte() {
    let bd = pack("xB", &[PackValue::UInt(42)]).unwrap();
    assert_eq!(bd.as_bytes().len(), 2);
    assert_eq!(bd.as_bytes()[0], 0);
    assert_eq!(bd.as_bytes()[1], 42);
}

#[test]
fn data_pack_multi_type_round_trip() {
    let vals = &[
        PackValue::Int(-1i64),
        PackValue::UInt(255u64),
        PackValue::Double(1.5f64),
    ];
    let bd = pack("<bBd", vals).unwrap();
    let (out, pos) = unpack("<bBd", bd.as_bytes(), 0).unwrap();
    assert_eq!(pos, bd.as_bytes().len());
    if let PackValue::Int(v) = out[0] {
        assert_eq!(v, -1);
    } else {
        panic!("expected Int");
    }
    if let PackValue::UInt(v) = out[1] {
        assert_eq!(v, 255);
    } else {
        panic!("expected UInt");
    }
    if let PackValue::Double(v) = out[2] {
        assert!((v - 1.5).abs() < 1e-10);
    } else {
        panic!("expected Double");
    }
}

#[test]
fn data_dataview_f32_from_pack() {
    let bd = pack("<f", &[PackValue::Float(2.5f32)]).unwrap();
    use std::sync::Arc;
    let bytes = Arc::new(bd.as_bytes().to_vec());
    let dv = DataView::new(bytes);
    let v = dv.get_f32(0).unwrap();
    assert!((v - 2.5f32).abs() < 1e-6);
}
