//! Core NdArray type and DataType enum.
//!
//! This module is part of Luna2D's `compute` subsystem and provides the implementation
//! details for array-related operations and data management.
//! Key types exported from this module: `DataType`, `NdArray`.
//! Primary functions: `parse()`, `byte_size()`, `name()`, `new()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Maximum number of elements allowed in a single NdArray.
const MAX_ELEMENTS: usize = 268_435_456;

/// Element data type for an NdArray. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Float32` — Float32 variant.
/// - `Float64` — Float64 variant.
/// - `Int32` — Int32 variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DataType {
    /// 32-bit IEEE 754 floating point (4 bytes).
    Float32,
    /// 64-bit IEEE 754 floating point (8 bytes).
    Float64,
    /// 32-bit signed integer (4 bytes).
    Int32,
}

impl DataType {
    /// Parse a dtype from a string name (`"float32"`, `"float64"`, `"int32"`).
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn parse(s: &str) -> Result<Self, String> {
        match s {
            "float32" => Ok(DataType::Float32),
            "float64" => Ok(DataType::Float64),
            "int32" => Ok(DataType::Int32),
            _ => Err(format!(
                "unknown dtype '{s}', expected float32|float64|int32"
            )),
        }
    }

    /// Number of bytes per element for this dtype.
    ///
    /// # Returns
    /// `usize`.
    pub fn byte_size(self) -> usize {
        match self {
            DataType::Float32 => 4,
            DataType::Float64 => 8,
            DataType::Int32 => 4,
        }
    }

    /// Human-readable name for this dtype. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn name(self) -> &'static str {
        match self {
            DataType::Float32 => "float32",
            DataType::Float64 => "float64",
            DataType::Int32 => "int32",
        }
    }
}

/// Dense N-dimensional numerical array with row-major strides.
///
/// Data is stored as a contiguous `Vec<u8>` byte buffer. Shapes are limited
/// to 1D, 2D, or 3D with a hard cap of 268,435,456 elements.
///
/// # Fields
/// - `shape` — `Vec<usize>`.
/// - `strides` — `Vec<usize>`.
/// - `dtype` — `DataType`.
/// - `data` — `Vec<u8>`.
#[derive(Debug, Clone)]
pub struct NdArray {
    shape: Vec<usize>,
    strides: Vec<usize>,
    dtype: DataType,
    data: Vec<u8>,
}

impl NdArray {
    /// Create a new zero-initialized NdArray with the given shape and dtype.
    ///
    /// # Parameters
    /// - `shape` — `&[usize]`.
    /// - `dtype` — `DataType`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn new(shape: &[usize], dtype: DataType) -> Result<Self, String> {
        Self::zeros(shape, dtype)
    }

    /// Create a zero-initialized NdArray. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `shape` — `&[usize]`.
    /// - `dtype` — `DataType`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn zeros(shape: &[usize], dtype: DataType) -> Result<Self, String> {
        Self::validate_shape(shape)?;
        let total = Self::element_count(shape);
        let strides = Self::compute_strides(shape);
        let data = vec![0u8; total * dtype.byte_size()];
        Ok(NdArray {
            shape: shape.to_vec(),
            strides,
            dtype,
            data,
        })
    }

    /// Create an NdArray filled with ones (1.0 for floats, 1 for int32).
    ///
    /// # Parameters
    /// - `shape` — `&[usize]`.
    /// - `dtype` — `DataType`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn ones(shape: &[usize], dtype: DataType) -> Result<Self, String> {
        let mut arr = Self::zeros(shape, dtype)?;
        let total = arr.size();
        for i in 0..total {
            arr.set_f64(i, 1.0);
        }
        Ok(arr)
    }

    /// Create a 1D NdArray with values from `start` to `stop` (exclusive) with given step.
    ///
    /// # Parameters
    /// - `start` — `f64`.
    /// - `stop` — `f64`.
    /// - `step` — `f64`.
    /// - `dtype` — `DataType`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn range(start: f64, stop: f64, step: f64, dtype: DataType) -> Result<Self, String> {
        if step == 0.0 {
            return Err("step must not be zero".to_string());
        }
        if (stop - start) / step < 0.0 {
            return Err("range would produce no elements (step direction mismatch)".to_string());
        }
        let count = ((stop - start) / step).ceil() as usize;
        if count > MAX_ELEMENTS {
            return Err(format!(
                "range would produce {count} elements, exceeding max {MAX_ELEMENTS}"
            ));
        }
        let mut arr = Self::zeros(&[count], dtype)?;
        for i in 0..count {
            arr.set_f64(i, start + (i as f64) * step);
        }
        Ok(arr)
    }

    /// Create an NdArray from a slice of f64 values, converting to the target dtype.
    ///
    /// # Parameters
    /// - `values` — `&[f64]`.
    /// - `shape` — `&[usize]`.
    /// - `dtype` — `DataType`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn from_slice(values: &[f64], shape: &[usize], dtype: DataType) -> Result<Self, String> {
        Self::validate_shape(shape)?;
        let total = Self::element_count(shape);
        if values.len() != total {
            return Err(format!(
                "data length {} does not match shape element count {total}",
                values.len()
            ));
        }
        let mut arr = Self::zeros(shape, dtype)?;
        for (i, &v) in values.iter().enumerate() {
            arr.set_f64(i, v);
        }
        Ok(arr)
    }

    /// Read element at flat index as f64 (works for any dtype).
    ///
    /// # Parameters
    /// - `flat` — `usize`.
    ///
    /// # Returns
    /// `f64`.
    pub fn get_f64(&self, flat: usize) -> f64 {
        let offset = flat * self.dtype.byte_size();
        match self.dtype {
            DataType::Float32 => {
                let bytes: [u8; 4] = self.data[offset..offset + 4].try_into().unwrap();
                f32::from_le_bytes(bytes) as f64
            }
            DataType::Float64 => {
                let bytes: [u8; 8] = self.data[offset..offset + 8].try_into().unwrap();
                f64::from_le_bytes(bytes)
            }
            DataType::Int32 => {
                let bytes: [u8; 4] = self.data[offset..offset + 4].try_into().unwrap();
                i32::from_le_bytes(bytes) as f64
            }
        }
    }

    /// Write a value (as f64) to the flat index, converting to the array's dtype.
    ///
    /// # Parameters
    /// - `flat` — `usize`.
    /// - `val` — `f64`.
    pub fn set_f64(&mut self, flat: usize, val: f64) {
        let offset = flat * self.dtype.byte_size();
        match self.dtype {
            DataType::Float32 => {
                let bytes = (val as f32).to_le_bytes();
                self.data[offset..offset + 4].copy_from_slice(&bytes);
            }
            DataType::Float64 => {
                let bytes = val.to_le_bytes();
                self.data[offset..offset + 8].copy_from_slice(&bytes);
            }
            DataType::Int32 => {
                let bytes = (val as i32).to_le_bytes();
                self.data[offset..offset + 4].copy_from_slice(&bytes);
            }
        }
    }

    /// Read element at flat index as i32. Only meaningful for Int32 arrays.
    ///
    /// # Parameters
    /// - `flat` — `usize`.
    ///
    /// # Returns
    /// `i32`.
    pub fn get_i32(&self, flat: usize) -> i32 {
        let offset = flat * self.dtype.byte_size();
        let bytes: [u8; 4] = self.data[offset..offset + 4].try_into().unwrap();
        i32::from_le_bytes(bytes)
    }

    /// Write an i32 value at the flat index. Only meaningful for Int32 arrays.
    ///
    /// # Parameters
    /// - `flat` — `usize`.
    /// - `val` — `i32`.
    pub fn set_i32(&mut self, flat: usize, val: i32) {
        let offset = flat * self.dtype.byte_size();
        let bytes = val.to_le_bytes();
        self.data[offset..offset + 4].copy_from_slice(&bytes);
    }

    /// Convert a multi-dimensional index to a flat element offset.
    ///
    /// # Parameters
    /// - `indices` — `&[usize]`.
    ///
    /// # Returns
    /// `Result<usize, String>`.
    ///
    /// All indices are 0-based. Returns an error if indices are out of bounds
    /// or the wrong number of dimensions is provided.
    pub fn flat_index(&self, indices: &[usize]) -> Result<usize, String> {
        if indices.len() != self.shape.len() {
            return Err(format!(
                "expected {} indices, got {}",
                self.shape.len(),
                indices.len()
            ));
        }
        let mut flat = 0usize;
        for (i, &idx) in indices.iter().enumerate() {
            if idx >= self.shape[i] {
                return Err(format!(
                    "index {} out of bounds for axis {} with size {}",
                    idx, i, self.shape[i]
                ));
            }
            flat += idx * self.strides[i];
        }
        Ok(flat)
    }

    /// Returns the shape of this array as a slice.
    ///
    /// # Returns
    /// `&[usize]`.
    pub fn shape(&self) -> &[usize] {
        &self.shape
    }

    /// Returns the element data type of this array.
    ///
    /// # Returns
    /// `DataType`.
    pub fn dtype(&self) -> DataType {
        self.dtype
    }

    /// Returns the total number of elements in this array.
    ///
    /// # Returns
    /// `usize`.
    pub fn size(&self) -> usize {
        Self::element_count(&self.shape)
    }

    /// Returns the number of dimensions (1, 2, or 3).
    ///
    /// # Returns
    /// `usize`.
    pub fn ndim(&self) -> usize {
        self.shape.len()
    }

    /// Returns the row-major strides for this array.
    ///
    /// # Returns
    /// `&[usize]`.
    pub fn strides(&self) -> &[usize] {
        &self.strides
    }

    /// Returns a reference to the underlying byte data.
    ///
    /// # Returns
    /// `&[u8]`.
    pub fn data(&self) -> &[u8] {
        &self.data
    }

    /// Returns a mutable reference to the underlying byte data.
    ///
    /// # Returns
    /// `&mut [u8]`.
    pub fn data_mut(&mut self) -> &mut [u8] {
        &mut self.data
    }

    /// Sets the shape and strides directly. Used by reshape.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    pub(crate) fn set_shape(&mut self, shape: Vec<usize>, strides: Vec<usize>) {
        self.shape = shape;
        self.strides = strides;
    }

    /// Compute row-major strides for a given shape.
    ///
    /// # Parameters
    /// - `shape` — `&[usize]`.
    ///
    /// # Returns
    /// `Vec<usize>`.
    ///
    /// `strides[i] = product(shape[i+1..])` — so the last axis has stride 1.
    pub fn compute_strides(shape: &[usize]) -> Vec<usize> {
        let ndim = shape.len();
        let mut strides = vec![1usize; ndim];
        for i in (0..ndim.saturating_sub(1)).rev() {
            strides[i] = strides[i + 1] * shape[i + 1];
        }
        strides
    }

    /// Validate shape constraints (1-3 dims, element count within limits).
    fn validate_shape(shape: &[usize]) -> Result<(), String> {
        if shape.is_empty() || shape.len() > 3 {
            return Err(format!("ndim must be 1, 2, or 3, got {}", shape.len()));
        }
        let total = Self::element_count(shape);
        if total > MAX_ELEMENTS {
            return Err(format!(
                "element count {total} exceeds maximum {MAX_ELEMENTS}"
            ));
        }
        if total == 0 {
            return Err("array must have at least one element".to_string());
        }
        Ok(())
    }

    /// Total number of elements for a given shape.
    fn element_count(shape: &[usize]) -> usize {
        shape.iter().product()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dtype_from_str() {
        assert_eq!(DataType::parse("float32").unwrap(), DataType::Float32);
        assert_eq!(DataType::parse("float64").unwrap(), DataType::Float64);
        assert_eq!(DataType::parse("int32").unwrap(), DataType::Int32);
        assert!(DataType::parse("uint8").is_err());
    }

    #[test]
    fn test_dtype_byte_size() {
        assert_eq!(DataType::Float32.byte_size(), 4);
        assert_eq!(DataType::Float64.byte_size(), 8);
        assert_eq!(DataType::Int32.byte_size(), 4);
    }

    #[test]
    fn test_zeros() {
        let a = NdArray::zeros(&[3, 4], DataType::Float32).unwrap();
        assert_eq!(a.shape(), &[3, 4]);
        assert_eq!(a.size(), 12);
        assert_eq!(a.ndim(), 2);
        for i in 0..12 {
            assert!((a.get_f64(i) - 0.0).abs() < 1e-10);
        }
    }

    #[test]
    fn test_ones() {
        let a = NdArray::ones(&[2, 3], DataType::Float64).unwrap();
        for i in 0..6 {
            assert!((a.get_f64(i) - 1.0).abs() < 1e-10);
        }
    }

    #[test]
    fn test_range() {
        let a = NdArray::range(0.0, 5.0, 1.0, DataType::Float32).unwrap();
        assert_eq!(a.shape(), &[5]);
        for i in 0..5 {
            assert!((a.get_f64(i) - i as f64).abs() < 1e-5);
        }
    }

    #[test]
    fn test_from_slice() {
        let vals = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let a = NdArray::from_slice(&vals, &[2, 3], DataType::Float32).unwrap();
        assert_eq!(a.shape(), &[2, 3]);
        assert!((a.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((a.get_f64(5) - 6.0).abs() < 1e-5);
    }

    #[test]
    fn test_flat_index() {
        let a = NdArray::zeros(&[3, 4], DataType::Float32).unwrap();
        assert_eq!(a.flat_index(&[0, 0]).unwrap(), 0);
        assert_eq!(a.flat_index(&[1, 0]).unwrap(), 4);
        assert_eq!(a.flat_index(&[2, 3]).unwrap(), 11);
        assert!(a.flat_index(&[3, 0]).is_err());
    }

    #[test]
    fn test_int32_access() {
        let mut a = NdArray::zeros(&[4], DataType::Int32).unwrap();
        a.set_i32(0, 42);
        a.set_i32(1, -7);
        assert_eq!(a.get_i32(0), 42);
        assert_eq!(a.get_i32(1), -7);
        assert!((a.get_f64(0) - 42.0).abs() < 1e-5);
    }

    #[test]
    fn test_strides() {
        assert_eq!(NdArray::compute_strides(&[5]), vec![1]);
        assert_eq!(NdArray::compute_strides(&[3, 4]), vec![4, 1]);
        assert_eq!(NdArray::compute_strides(&[2, 3, 4]), vec![12, 4, 1]);
    }

    #[test]
    fn test_shape_validation() {
        assert!(NdArray::zeros(&[], DataType::Float32).is_err());
        assert!(NdArray::zeros(&[1, 2, 3, 4], DataType::Float32).is_err());
        assert!(NdArray::zeros(&[0], DataType::Float32).is_err());
    }

    #[test]
    fn test_range_errors() {
        assert!(NdArray::range(0.0, 5.0, 0.0, DataType::Float32).is_err());
        assert!(NdArray::range(0.0, 5.0, -1.0, DataType::Float32).is_err());
    }

    #[test]
    fn test_from_slice_mismatch() {
        let vals = vec![1.0, 2.0, 3.0];
        assert!(NdArray::from_slice(&vals, &[2, 3], DataType::Float32).is_err());
    }
}
