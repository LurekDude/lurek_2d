//! Border classification logic: derives BorderClass from two adjacent ProvinceStyle values.
//! Used by registry, render, and import to label shared edges.
use crate::province::types::{BorderClass, ProvinceStyle};

/// Classify the shared border between provinces with styles a and b; uses terrain_type == 0 as the water test.
pub fn classify_border(a: &ProvinceStyle, b: &ProvinceStyle) -> BorderClass {
    let a_water = a.terrain_type == 0;
    let b_water = b.terrain_type == 0;
    match (a_water, b_water) {
        (false, false) => BorderClass::LandLand,
        (true, true) => BorderClass::SeaSea,
        _ => BorderClass::Coast,
    }
}
