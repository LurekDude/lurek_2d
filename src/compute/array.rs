//! Typed n-dimensional dense array storage used by compute modules.
//! Owns shape validation, stride math, typed scalar conversion, and constructors.
//! Keeps byte-buffer representation isolated from operation-level algorithms.
//! Depends only on std containers and numeric casting.

/// Defines maximum allowed number of elements for safe allocations.
const MAX_ELEMENTS: usize = 268_435_456;

#[derive(Debug, Clone, Copy, PartialEq)]
/// Selects scalar storage type used by an NdArray instance.
pub enum DataType {
    /// Stores values as IEEE-754 32-bit floats.
    Float32,
    /// Stores values as IEEE-754 64-bit floats.
    Float64,
    /// Stores values as signed 32-bit integers.
    Int32,
}
impl DataType {
    /// Parse dtype string and return matching DataType or parse error.
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
    /// Return byte width of dtype element representation.
    pub fn byte_size(self) -> usize {
        match self {
            DataType::Float32 => 4,
            DataType::Float64 => 8,
            DataType::Int32 => 4,
        }
    }
    /// Return canonical dtype name string.
    pub fn name(self) -> &'static str {
        match self {
            DataType::Float32 => "float32",
            DataType::Float64 => "float64",
            DataType::Int32 => "int32",
        }
    }
}

#[derive(Debug, Clone)]
/// Stores dense n-dimensional array metadata and raw typed element bytes.
pub struct NdArray {
    /// Stores axis lengths in row-major order.
    shape: Vec<usize>,
    /// Stores row-major strides in elements for each axis.
    strides: Vec<usize>,
    /// Stores scalar data type for element conversion.
    dtype: DataType,
    /// Stores contiguous element bytes in native layout for dtype.
    data: Vec<u8>,
}
impl NdArray {
    /// Create zero-initialized array and return it for shape and dtype.
    pub fn new(shape: &[usize], dtype: DataType) -> Result<Self, String> {
        Self::zeros(shape, dtype)
    }
    /// Allocate zero-filled array and return it after validating shape limits.
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
    /// Allocate one-filled array and return initialized values.
    pub fn ones(shape: &[usize], dtype: DataType) -> Result<Self, String> {
        let mut arr = Self::zeros(shape, dtype)?;
        let total = arr.size();
        for i in 0..total {
            arr.set_f64(i, 1.0);
        }
        Ok(arr)
    }
    /// Build 1D range array and return values from start to stop with step.
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
    /// Build array from f64 slice and return typed array with requested shape.
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
    /// Read element by flat index and return value converted to f64.
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
    /// Write f64 value by flat index and return after dtype conversion.
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
    /// Read element as i32 by flat index and return integer value.
    pub fn get_i32(&self, flat: usize) -> i32 {
        let offset = flat * self.dtype.byte_size();
        let bytes: [u8; 4] = self.data[offset..offset + 4]
            .try_into()
            .expect("byte slice invariant: offset validated by flat_index");
        i32::from_le_bytes(bytes)
    }
    /// Write i32 value by flat index and return after byte update.
    pub fn set_i32(&mut self, flat: usize, val: i32) {
        let offset = flat * self.dtype.byte_size();
        let bytes = val.to_le_bytes();
        self.data[offset..offset + 4].copy_from_slice(&bytes);
    }
    /// Convert multidimensional indices to flat index and return offset.
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
    /// Read shape slice and return axis lengths.
    pub fn shape(&self) -> &[usize] {
        &self.shape
    }
    /// Read scalar dtype and return DataType value.
    pub fn dtype(&self) -> DataType {
        self.dtype
    }
    /// Read element count and return total number of elements.
    pub fn size(&self) -> usize {
        Self::element_count(&self.shape)
    }
    /// Read number of dimensions and return ndim value.
    pub fn ndim(&self) -> usize {
        self.shape.len()
    }
    /// Read stride slice and return per-axis element strides.
    pub fn strides(&self) -> &[usize] {
        &self.strides
    }
    /// Read immutable byte buffer and return raw data slice.
    pub fn data(&self) -> &[u8] {
        &self.data
    }
    /// Read mutable byte buffer and return raw mutable data slice.
    pub fn data_mut(&mut self) -> &mut [u8] {
        &mut self.data
    }
    /// Replace shape and stride metadata and return after metadata update.
    pub(crate) fn set_shape(&mut self, shape: Vec<usize>, strides: Vec<usize>) {
        self.shape = shape;
        self.strides = strides;
    }
    /// Compute row-major strides and return stride vector for provided shape.
    pub fn compute_strides(shape: &[usize]) -> Vec<usize> {
        let ndim = shape.len();
        let mut strides = vec![1usize; ndim];
        for i in (0..ndim.saturating_sub(1)).rev() {
            strides[i] = strides[i + 1] * shape[i + 1];
        }
        strides
    }
    /// Validate shape and return error when dimensions or size are invalid.
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
    /// Read element by multidimensional indices and return f64 value.
    pub fn get_by_indices(&self, indices: &[usize]) -> Result<f64, String> {
        let flat = self.flat_index(indices)?;
        Ok(self.get_f64(flat))
    }
    /// Write element by multidimensional indices and return success status.
    pub fn set_by_indices(&mut self, indices: &[usize], val: f64) -> Result<(), String> {
        let flat = self.flat_index(indices)?;
        self.set_f64(flat, val);
        Ok(())
    }
    /// Convert all elements to f64 and return copied vector.
    pub fn to_f64_vec(&self) -> Vec<f64> {
        (0..self.size()).map(|i| self.get_f64(i)).collect()
    }
    /// Fill all elements with scalar value and return after mutation.
    pub fn fill(&mut self, val: f64) {
        for i in 0..self.size() {
            self.set_f64(i, val);
        }
    }
    /// Map function over elements and return new array with mapped values.
    pub fn map(&self, f: fn(f64) -> f64) -> Result<Self, String> {
        let mut out = Self::zeros(self.shape(), self.dtype())?;
        for i in 0..self.size() {
            out.set_f64(i, f(self.get_f64(i)));
        }
        Ok(out)
    }
    /// Iterate elements as f64 values and return lazy iterator.
    pub fn iter_f64(&self) -> impl Iterator<Item = f64> + '_ {
        (0..self.size()).map(|i| self.get_f64(i))
    }
    /// Format array summary and return short display string.
    pub fn display_string(&self) -> String {
        format!("Array({:?}, dtype={})", self.shape, self.dtype.name())
    }
    /// Compute total element count for shape and return product.
    fn element_count(shape: &[usize]) -> usize {
        shape.iter().product()
    }
}
