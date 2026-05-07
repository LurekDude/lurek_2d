//! Core NdArray type and DataType enum.
//!
//! This module is part of Lurek2D's `compute` subsystem and provides the implementation
//! details for array-related operations and data management.
//! Key types exported from this module: `DataType`, `NdArray`.
//! Primary functions: `parse()`, `byte_size()`, `name()`, `new()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// Maximum number of elements allowed in a single NdArray.
const MAX_ELEMENTS: usize = 268_435_456;

/// Element data type for an NdArray.
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

    /// Human-readable name for this dtype.
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
/// Data is stored as a contiguous `Vec<u8>` byte buffer with a hard cap
/// of 268,435,456 elements.
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

    /// Create a zero-initialized NdArray.
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
        log::debug!("ndarray: allocating {} elements", total);
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
                let bytes: [u8; 4] = self.data[offset..offset + 4]
                    .try_into()
                    .expect("byte slice invariant: offset validated by flat_index");
                f32::from_le_bytes(bytes) as f64
            }
            DataType::Float64 => {
                let bytes: [u8; 8] = self.data[offset..offset + 8]
                    .try_into()
                    .expect("byte slice invariant: offset validated by flat_index");
                f64::from_le_bytes(bytes)
            }
            DataType::Int32 => {
                let bytes: [u8; 4] = self.data[offset..offset + 4]
                    .try_into()
                    .expect("byte slice invariant: offset validated by flat_index");
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
        let bytes: [u8; 4] = self.data[offset..offset + 4]
            .try_into()
            .expect("byte slice invariant: offset validated by flat_index");
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

    /// Returns the number of dimensions.
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
    /// `strides[i] = product(shape[i+1.])` — so the last axis has stride 1.
    pub fn compute_strides(shape: &[usize]) -> Vec<usize> {
        let ndim = shape.len();
        let mut strides = vec![1usize; ndim];
        for i in (0..ndim.saturating_sub(1)).rev() {
            strides[i] = strides[i + 1] * shape[i + 1];
        }
        strides
    }

    /// Validate shape constraints (at least 1 dim, element count within limits).
    fn validate_shape(shape: &[usize]) -> Result<(), String> {
        if shape.is_empty() {
            return Err("ndim must be >= 1".to_string());
        }
        let total = Self::element_count(shape);
        if total > MAX_ELEMENTS {
            log::warn!(
                "ndarray: element count {} exceeds safety limit {}",
                total,
                MAX_ELEMENTS
            );
            return Err(format!(
                "element count {total} exceeds maximum {MAX_ELEMENTS}"
            ));
        }
        if total == 0 {
            return Err("array must have at least one element".to_string());
        }
        Ok(())
    }

    /// Read element by multi-dimensional indices (0-based), combining flat_index + get_f64.
    ///
    /// # Parameters
    /// - `indices` — `&[usize]`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn get_by_indices(&self, indices: &[usize]) -> Result<f64, String> {
        let flat = self.flat_index(indices)?;
        Ok(self.get_f64(flat))
    }

    /// Write a value by multi-dimensional indices (0-based), combining flat_index + set_f64.
    ///
    /// # Parameters
    /// - `indices` — `&[usize]`.
    /// - `val` — `f64`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn set_by_indices(&mut self, indices: &[usize], val: f64) -> Result<(), String> {
        let flat = self.flat_index(indices)?;
        self.set_f64(flat, val);
        Ok(())
    }

    /// Return all elements as a `Vec<f64>`.
    ///
    /// # Returns
    /// `Vec<f64>`.
    pub fn to_f64_vec(&self) -> Vec<f64> {
        (0..self.size()).map(|i| self.get_f64(i)).collect()
    }

    /// Fill all elements with the same value, in place.
    ///
    /// # Parameters
    /// - `val` - `f64` value written to every element.
    pub fn fill(&mut self, val: f64) {
        for i in 0..self.size() {
            self.set_f64(i, val);
        }
    }

    /// Map each element through `f` and return a new array.
    ///
    /// # Parameters
    /// - `f` - function called once per element.
    ///
    /// # Returns
    /// `Result<NdArray, String>`.
    pub fn map(&self, f: fn(f64) -> f64) -> Result<Self, String> {
        let mut out = Self::zeros(self.shape(), self.dtype())?;
        for i in 0..self.size() {
            out.set_f64(i, f(self.get_f64(i)));
        }
        Ok(out)
    }

    /// Iterate over values converted to f64.
    ///
    /// # Returns
    /// `impl Iterator<Item = f64> + '_`.
    pub fn iter_f64(&self) -> impl Iterator<Item = f64> + '_ {
        (0..self.size()).map(|i| self.get_f64(i))
    }

    /// Return a human-readable summary string for debugging.
    ///
    /// # Returns
    /// `String`.
    pub fn display_string(&self) -> String {
        format!("Array({:?}, dtype={})", self.shape, self.dtype.name())
    }

    /// Total number of elements for a given shape.
    fn element_count(shape: &[usize]) -> usize {
        shape.iter().product()
    }
}
