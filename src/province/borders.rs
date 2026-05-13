use crate::province::types::{BorderClass, ProvinceStyle};
pub fn classify_border(a: &ProvinceStyle, b: &ProvinceStyle) -> BorderClass {
    let a_water = a.terrain_type == 0;
    let b_water = b.terrain_type == 0;
    match (a_water, b_water) {
        (false, false) => BorderClass::LandLand,
        (true, true) => BorderClass::SeaSea,
        _ => BorderClass::Coast,
    }
}
