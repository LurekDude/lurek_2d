const MAX_ELEMENTS: usize = 268_435_456;
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DataType {
    Float32,
    Float64,
    Int32,
}
impl DataType {
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
    pub fn byte_size(self) -> usize {
        match self {
            DataType::Float32 => 4,
            DataType::Float64 => 8,
            DataType::Int32 => 4,
        }
    }
    pub fn name(self) -> &'static str {
        match self {
            DataType::Float32 => "float32",
            DataType::Float64 => "float64",
            DataType::Int32 => "int32",
        }
    }
}
#[derive(Debug, Clone)]
pub struct NdArray {
    shape: Vec<usize>,
    strides: Vec<usize>,
    dtype: DataType,
    data: Vec<u8>,
}
impl NdArray {
    pub fn new(shape: &[usize], dtype: DataType) -> Result<Self, String> {
        Self::zeros(shape, dtype)
    }
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
    pub fn ones(shape: &[usize], dtype: DataType) -> Result<Self, String> {
        let mut arr = Self::zeros(shape, dtype)?;
        let total = arr.size();
        for i in 0..total {
            arr.set_f64(i, 1.0);
        }
        Ok(arr)
    }
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
    pub fn get_i32(&self, flat: usize) -> i32 {
        let offset = flat * self.dtype.byte_size();
        let bytes: [u8; 4] = self.data[offset..offset + 4]
            .try_into()
            .expect("byte slice invariant: offset validated by flat_index");
        i32::from_le_bytes(bytes)
    }
    pub fn set_i32(&mut self, flat: usize, val: i32) {
        let offset = flat * self.dtype.byte_size();
        let bytes = val.to_le_bytes();
        self.data[offset..offset + 4].copy_from_slice(&bytes);
    }
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
    pub fn shape(&self) -> &[usize] {
        &self.shape
    }
    pub fn dtype(&self) -> DataType {
        self.dtype
    }
    pub fn size(&self) -> usize {
        Self::element_count(&self.shape)
    }
    pub fn ndim(&self) -> usize {
        self.shape.len()
    }
    pub fn strides(&self) -> &[usize] {
        &self.strides
    }
    pub fn data(&self) -> &[u8] {
        &self.data
    }
    pub fn data_mut(&mut self) -> &mut [u8] {
        &mut self.data
    }
    pub(crate) fn set_shape(&mut self, shape: Vec<usize>, strides: Vec<usize>) {
        self.shape = shape;
        self.strides = strides;
    }
    pub fn compute_strides(shape: &[usize]) -> Vec<usize> {
        let ndim = shape.len();
        let mut strides = vec![1usize; ndim];
        for i in (0..ndim.saturating_sub(1)).rev() {
            strides[i] = strides[i + 1] * shape[i + 1];
        }
        strides
    }
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
    pub fn get_by_indices(&self, indices: &[usize]) -> Result<f64, String> {
        let flat = self.flat_index(indices)?;
        Ok(self.get_f64(flat))
    }
    pub fn set_by_indices(&mut self, indices: &[usize], val: f64) -> Result<(), String> {
        let flat = self.flat_index(indices)?;
        self.set_f64(flat, val);
        Ok(())
    }
    pub fn to_f64_vec(&self) -> Vec<f64> {
        (0..self.size()).map(|i| self.get_f64(i)).collect()
    }
    pub fn fill(&mut self, val: f64) {
        for i in 0..self.size() {
            self.set_f64(i, val);
        }
    }
    pub fn map(&self, f: fn(f64) -> f64) -> Result<Self, String> {
        let mut out = Self::zeros(self.shape(), self.dtype())?;
        for i in 0..self.size() {
            out.set_f64(i, f(self.get_f64(i)));
        }
        Ok(out)
    }
    pub fn iter_f64(&self) -> impl Iterator<Item = f64> + '_ {
        (0..self.size()).map(|i| self.get_f64(i))
    }
    pub fn display_string(&self) -> String {
        format!("Array({:?}, dtype={})", self.shape, self.dtype.name())
    }
    fn element_count(shape: &[usize]) -> usize {
        shape.iter().product()
    }
}
