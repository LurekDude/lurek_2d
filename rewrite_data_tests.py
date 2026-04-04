with open("tests/unit/data_tests.rs", "r", encoding="utf-8") as f:
    content = f.read()

# Find the TOML section and cut from there
cut_marker = "// ── Phase 31"
idx = content.find(cut_marker)
if idx == -1:
    print("ERROR: marker not found")
    exit(1)

before = content[:idx].rstrip()

new_part = r"""

// ── DataView tests ───────────────────────────────────────────────────────────

use luna2d::binary::DataView;

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

// ── Luna2D Binary Pack Format tests ──────────────────────────────────────────

use luna2d::binary::pack::{write, read, measure_size, BinValue};

#[test]
fn binary_write_read_u32_f32_roundtrip() {
    let bd = write("u32 f32", &[BinValue::U32(42), BinValue::F32(3.14)]).unwrap();
    let (vals, pos) = read("u32 f32", bd.as_bytes(), 0).unwrap();
    assert_eq!(pos, 8);
    if let BinValue::U32(n) = vals[0] { assert_eq!(n, 42); } else { panic!("expected U32"); }
    if let BinValue::F32(f) = vals[1] { assert!((f - 3.14f32).abs() < 1e-4); } else { panic!("expected F32"); }
}

#[test]
fn binary_write_read_str_roundtrip() {
    let bd = write("str", &[BinValue::Str("hello".to_string())]).unwrap();
    let (vals, _) = read("str", bd.as_bytes(), 0).unwrap();
    if let BinValue::Str(s) = &vals[0] { assert_eq!(s, "hello"); } else { panic!("expected Str"); }
}

#[test]
fn binary_write_read_cstr_roundtrip() {
    let bd = write("cstr", &[BinValue::Str("world".to_string())]).unwrap();
    assert_eq!(bd.as_bytes().len(), 6);
    let (vals, _) = read("cstr", bd.as_bytes(), 0).unwrap();
    if let BinValue::Str(s) = &vals[0] { assert_eq!(s, "world"); } else { panic!("expected Str"); }
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
    if let BinValue::Bool(b) = vals[0] { assert!(b); } else { panic!("expected Bool"); }
    if let BinValue::Bool(b) = vals[1] { assert!(!b); } else { panic!("expected Bool"); }
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
    let vals = &[
        BinValue::I8(-1),
        BinValue::U8(255),
        BinValue::F64(1.5),
    ];
    let bd = write("le i8 u8 f64", vals).unwrap();
    let (out, pos) = read("le i8 u8 f64", bd.as_bytes(), 0).unwrap();
    assert_eq!(pos, bd.as_bytes().len());
    if let BinValue::I8(v) = out[0] { assert_eq!(v, -1); } else { panic!("expected I8"); }
    if let BinValue::U8(v) = out[1] { assert_eq!(v, 255); } else { panic!("expected U8"); }
    if let BinValue::F64(v) = out[2] { assert!((v - 1.5).abs() < 1e-10); } else { panic!("expected F64"); }
}

#[test]
fn binary_offset_read() {
    let bd = write("u8 u8 u8", &[BinValue::U8(10), BinValue::U8(20), BinValue::U8(30)]).unwrap();
    let (vals, pos) = read("u8 u8", bd.as_bytes(), 1).unwrap();
    assert_eq!(pos, 3);
    if let BinValue::U8(v) = vals[0] { assert_eq!(v, 20); } else { panic!(); }
    if let BinValue::U8(v) = vals[1] { assert_eq!(v, 30); } else { panic!(); }
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
"""

with open("tests/unit/data_tests.rs", "w", encoding="utf-8") as f:
    f.write(before + new_part)
print("Done")
