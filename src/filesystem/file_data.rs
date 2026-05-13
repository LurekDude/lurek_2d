pub struct FileData {
    pub path: String,
    pub bytes: Vec<u8>,
}
impl FileData {
    pub fn new(path: String, bytes: Vec<u8>) -> Self {
        Self { path, bytes }
    }
    pub fn len(&self) -> usize {
        self.bytes.len()
    }
    pub fn is_empty(&self) -> bool {
        self.bytes.is_empty()
    }
    pub fn as_str(&self) -> Result<&str, std::str::Utf8Error> {
        std::str::from_utf8(&self.bytes)
    }
}
