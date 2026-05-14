//! Binary serialisation cache for province geometry: span runs and border segments.
//! Encode/decode round-trips through a versioned little-endian byte format (magic 0x50525643).
//! Does not store style data; that is managed by ProvinceRegistry.
use crate::province::registry::ProvinceRegistry;

/// Serialisable snapshot of province geometry extracted from ProvinceRegistry.
#[derive(Debug, Clone)]
pub struct ProvinceGeometryCache {
    /// Pixel span runs: (province_id, row_y, x_start, x_end_exclusive).
    pub spans: Vec<(u32, u32, u32, u32)>,
    /// Border segments: (province_a, province_b, x0, y0, x1, y1).
    pub border_segments: Vec<(u32, u32, u32, u32, u32, u32)>,
}

impl ProvinceGeometryCache {
    /// Build a cache by copying spans and border_segments from the given registry.
    pub fn from_registry(registry: &ProvinceRegistry) -> Self {
        Self {
            spans: registry.spans().to_vec(),
            border_segments: registry.border_segments().to_vec(),
        }
    }

    /// Serialise to a versioned little-endian byte buffer; always succeeds.
    pub fn encode(&self) -> Vec<u8> {
        const MAGIC: u32 = 0x5052_5643;
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

    /// Deserialise from a byte buffer produced by encode; return None on magic mismatch or truncation.
    pub fn decode(data: &[u8]) -> Option<Self> {
        /// Read a u32 from data at offset off, advancing off by 4; return None on underflow.
        fn read_u32(data: &[u8], off: &mut usize) -> Option<u32> {
            if *off + 4 > data.len() {
                return None;
            }
            let v =
                u32::from_le_bytes([data[*off], data[*off + 1], data[*off + 2], data[*off + 3]]);
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
        Self {
            spans: registry.spans().to_vec(),
            border_segments: registry.border_segments().to_vec(),
        }
    }
    pub fn encode(&self) -> Vec<u8> {
        const MAGIC: u32 = 0x5052_5643;
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
    pub fn decode(data: &[u8]) -> Option<Self> {
        fn read_u32(data: &[u8], off: &mut usize) -> Option<u32> {
            if *off + 4 > data.len() {
                return None;
            }
            let v =
                u32::from_le_bytes([data[*off], data[*off + 1], data[*off + 2], data[*off + 3]]);
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
