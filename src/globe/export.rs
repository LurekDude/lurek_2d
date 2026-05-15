//! - Export globe province geometry to standard mesh formats.
//! - Generate flat OBJ output with one named object per province polygon.
//! - Vertex data uses (lon, lat) mapping onto a 2D plane at z=0.

use crate::globe::registry::Globe;
use std::fmt::Write;
/// Export province polygons as a flat OBJ string with one object per province.
pub fn export_provinces_to_obj(globe: &Globe) -> String {
    let mut out = String::new();
    let mut vertex_base: u32 = 1;
    for province in globe.graph.iter() {
        let _ = writeln!(&mut out, "o province_{}", province.id);
        for (lat, lon) in &province.vertices {
            let _ = writeln!(&mut out, "v {} {} 0.0", lon, lat);
        }
        if province.vertices.len() >= 3 {
            let mut face = String::from("f");
            for i in 0..province.vertices.len() {
                let _ = write!(&mut face, " {}", vertex_base + i as u32);
            }
            let _ = writeln!(&mut out, "{}", face);
        }
        vertex_base += province.vertices.len() as u32;
    }
    out
}
