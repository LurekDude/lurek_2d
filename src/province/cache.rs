//! Cache serialization for province geometry.

use crate::province::registry::ProvinceRegistry;

/// Cache blob of precomputed province geometry.
#[derive(Debug, Clone)]
pub struct ProvinceGeometryCache {
    /// Fill spans `(province_id, y, x0, x1)`.
    pub spans: Vec<(u32, u32, u32, u32)>,
    /// Border segments `(a,b,x0,y0,x1,y1)`.
    pub border_segments: Vec<(u32, u32, u32, u32, u32, u32)>,
}

impl ProvinceGeometryCache {
    /// Builds cache from a registry snapshot.
    pub fn from_registry(registry: &ProvinceRegistry) -> Self {
        Self {
            spans: registry.spans().to_vec(),
            border_segments: registry.border_segments().to_vec(),
        }
    }

    /// Encodes cache to a compact little-endian blob.
    pub fn encode(&self) -> Vec<u8> {
        const MAGIC: u32 = 0x5052_5643; // PRVC
        const VERSION: u32 = 1;
        let mut out = Vec::new();
        out.extend_from_slice(&MAGIC.to_le_bytes());
        out.extend_from_slice(&VERSION.to_le_bytes());

        out.extend_from_slice(&(self.spans.len() as u32).to_le_bytes());
        for (id, y, x0, x1) in &self.spans {
            out.extend_from_slice(&id.to_le_bytes());
            out.extend_from_slice(&y.to_le_bytes());
            out.extend_from_slice(&x0.to_le_bytes());
            out.extend_from_slice(&x1.to_le_bytes());
        }

        out.extend_from_slice(&(self.border_segments.len() as u32).to_le_bytes());
        for (a, b, x0, y0, x1, y1) in &self.border_segments {
            out.extend_from_slice(&a.to_le_bytes());
            out.extend_from_slice(&b.to_le_bytes());
            out.extend_from_slice(&x0.to_le_bytes());
            out.extend_from_slice(&y0.to_le_bytes());
            out.extend_from_slice(&x1.to_le_bytes());
            out.extend_from_slice(&y1.to_le_bytes());
        }
        out
    }

    /// Decodes cache from bytes.
    pub fn decode(data: &[u8]) -> Option<Self> {
        fn read_u32(data: &[u8], off: &mut usize) -> Option<u32> {
            if *off + 4 > data.len() {
                return None;
            }
            let v = u32::from_le_bytes([
                data[*off],
                data[*off + 1],
                data[*off + 2],
                data[*off + 3],
            ]);
            *off += 4;
            Some(v)
        }

        let mut off = 0usize;
        let magic = read_u32(data, &mut off)?;
        if magic != 0x5052_5643 {
            return None;
        }
        let _version = read_u32(data, &mut off)?;

        let span_count = read_u32(data, &mut off)? as usize;
        let mut spans = Vec::with_capacity(span_count);
        for _ in 0..span_count {
            spans.push((
                read_u32(data, &mut off)?,
                read_u32(data, &mut off)?,
                read_u32(data, &mut off)?,
                read_u32(data, &mut off)?,
            ));
        }

        let seg_count = read_u32(data, &mut off)? as usize;
        let mut border_segments = Vec::with_capacity(seg_count);
        for _ in 0..seg_count {
            border_segments.push((
                read_u32(data, &mut off)?,
                read_u32(data, &mut off)?,
                read_u32(data, &mut off)?,
                read_u32(data, &mut off)?,
                read_u32(data, &mut off)?,
                read_u32(data, &mut off)?,
            ));
        }

        Some(Self {
            spans,
            border_segments,
        })
    }
}
