use luna2d::filesystem::{FileHandle, FileMode, FileType, GameFS};
use tempfile::TempDir;

fn make_test_fs() -> (TempDir, GameFS) {
    let tmp = TempDir::new().expect("Failed to create temp dir");
    let fs = GameFS::new(tmp.path());
    // Create save/ directory for write operations
    std::fs::create_dir_all(tmp.path().join("save")).unwrap();
    (tmp, fs)
}

// ── FileHandle read/write roundtrip ───────────────────────────────

#[test]
fn file_handle_write_and_read_roundtrip() {
    let (_tmp, fs) = make_test_fs();
    let content = "Hello, Luna2D!";

    // Write
    let mut wh = FileHandle::open(&fs, "save/test.txt", FileMode::Write).unwrap();
    wh.write(content.as_bytes()).unwrap();
    wh.close().unwrap();

    // Read
    let mut rh = FileHandle::open(&fs, "save/test.txt", FileMode::Read).unwrap();
    let data = rh.read(None).unwrap();
    assert_eq!(String::from_utf8_lossy(&data), content);
}

#[test]
fn file_handle_read_with_count() {
    let (_tmp, fs) = make_test_fs();

    let mut wh = FileHandle::open(&fs, "save/partial.txt", FileMode::Write).unwrap();
    wh.write(b"ABCDEFGH").unwrap();
    wh.close().unwrap();

    let mut rh = FileHandle::open(&fs, "save/partial.txt", FileMode::Read).unwrap();
    let data = rh.read(Some(4)).unwrap();
    assert_eq!(data, b"ABCD");
    let data = rh.read(Some(4)).unwrap();
    assert_eq!(data, b"EFGH");
}

// ── FileHandle seek/tell ──────────────────────────────────────────

#[test]
fn file_handle_seek_and_tell() {
    let (_tmp, fs) = make_test_fs();

    let mut wh = FileHandle::open(&fs, "save/seek.txt", FileMode::Write).unwrap();
    wh.write(b"0123456789").unwrap();
    wh.close().unwrap();

    let mut rh = FileHandle::open(&fs, "save/seek.txt", FileMode::Read).unwrap();
    assert_eq!(rh.tell().unwrap(), 0);
    rh.seek(5).unwrap();
    assert_eq!(rh.tell().unwrap(), 5);
    let data = rh.read(Some(3)).unwrap();
    assert_eq!(data, b"567");
    assert_eq!(rh.tell().unwrap(), 8);
}

// ── Read line by line ─────────────────────────────────────────────

#[test]
fn file_handle_read_line_by_line() {
    let (_tmp, fs) = make_test_fs();

    let mut wh = FileHandle::open(&fs, "save/lines.txt", FileMode::Write).unwrap();
    wh.write(b"line1\nline2\nline3\n").unwrap();
    wh.close().unwrap();

    let mut rh = FileHandle::open(&fs, "save/lines.txt", FileMode::Read).unwrap();
    assert_eq!(rh.read_line().unwrap(), Some("line1".to_string()));
    assert_eq!(rh.read_line().unwrap(), Some("line2".to_string()));
    assert_eq!(rh.read_line().unwrap(), Some("line3".to_string()));
    assert_eq!(rh.read_line().unwrap(), None); // EOF
}

// ── FileHandle EOF ────────────────────────────────────────────────

#[test]
fn file_handle_eof_detection() {
    let (_tmp, fs) = make_test_fs();

    let mut wh = FileHandle::open(&fs, "save/eof.txt", FileMode::Write).unwrap();
    wh.write(b"AB").unwrap();
    wh.close().unwrap();

    let mut rh = FileHandle::open(&fs, "save/eof.txt", FileMode::Read).unwrap();
    assert!(!rh.is_eof().unwrap());
    rh.read(None).unwrap();
    assert!(rh.is_eof().unwrap());
}

// ── FileHandle mode ───────────────────────────────────────────────

#[test]
fn file_handle_get_mode() {
    let (_tmp, fs) = make_test_fs();

    let mut wh = FileHandle::open(&fs, "save/mode.txt", FileMode::Write).unwrap();
    assert_eq!(wh.get_mode(), FileMode::Write);
    assert_eq!(wh.get_mode().as_str(), "w");
    wh.close().unwrap();
    assert_eq!(wh.get_mode(), FileMode::Closed);
    assert_eq!(wh.get_mode().as_str(), "c");
}

// ── FileHandle get_size ───────────────────────────────────────────

#[test]
fn file_handle_get_size() {
    let (_tmp, fs) = make_test_fs();

    let mut wh = FileHandle::open(&fs, "save/size.txt", FileMode::Write).unwrap();
    wh.write(b"12345").unwrap();
    wh.close().unwrap();

    let rh = FileHandle::open(&fs, "save/size.txt", FileMode::Read).unwrap();
    assert_eq!(rh.get_size(), 5);
}

// ── Directory listing (sorted) ───────────────────────────────────

#[test]
fn get_directory_items_sorted() {
    let (tmp, fs) = make_test_fs();
    let save = tmp.path().join("save");
    std::fs::write(save.join("charlie.txt"), "c").unwrap();
    std::fs::write(save.join("alpha.txt"), "a").unwrap();
    std::fs::write(save.join("bravo.txt"), "b").unwrap();

    let items = fs.get_directory_items("save").unwrap();
    assert_eq!(items, vec!["alpha.txt", "bravo.txt", "charlie.txt"]);
}

// ── Create nested directories ─────────────────────────────────────

#[test]
fn create_nested_directories() {
    let (tmp, fs) = make_test_fs();

    fs.create_directory("save/a/b/c").unwrap();
    assert!(tmp.path().join("save/a/b/c").is_dir());
}

// ── Remove files and directories ──────────────────────────────────

#[test]
fn remove_file_in_save() {
    let (tmp, fs) = make_test_fs();
    let file_path = tmp.path().join("save/delete_me.txt");
    std::fs::write(&file_path, "temp").unwrap();
    assert!(file_path.exists());

    fs.remove("save/delete_me.txt").unwrap();
    assert!(!file_path.exists());
}

#[test]
fn remove_empty_directory_in_save() {
    let (tmp, fs) = make_test_fs();
    let dir_path = tmp.path().join("save/empty_dir");
    std::fs::create_dir_all(&dir_path).unwrap();
    assert!(dir_path.exists());

    fs.remove("save/empty_dir").unwrap();
    assert!(!dir_path.exists());
}

// ── getInfo returns correct metadata ──────────────────────────────

#[test]
fn get_info_file() {
    let (tmp, fs) = make_test_fs();
    std::fs::write(tmp.path().join("save/info.txt"), "hello").unwrap();

    let info = fs.get_info("save/info.txt").unwrap();
    assert_eq!(info.file_type, FileType::File);
    assert_eq!(info.size, 5);
    assert!(info.modified_time.is_some());
}

#[test]
fn get_info_directory() {
    let (_tmp, fs) = make_test_fs();

    let info = fs.get_info("save").unwrap();
    assert_eq!(info.file_type, FileType::Directory);
}

#[test]
fn get_info_nonexistent_returns_error() {
    let (_tmp, fs) = make_test_fs();
    assert!(fs.get_info("nonexistent").is_err());
}

// ── Path traversal prevention ─────────────────────────────────────

#[test]
fn path_traversal_read_rejected() {
    let (_tmp, fs) = make_test_fs();
    let result = fs.read_string("../../../etc/passwd");
    assert!(result.is_err());
}

#[test]
fn path_traversal_write_rejected() {
    let (_tmp, fs) = make_test_fs();
    let result = fs.write_string("save/../../etc/pwned", "bad");
    assert!(result.is_err());
}

// ── Write outside save rejected ──────────────────────────────────

#[test]
fn write_outside_save_rejected() {
    let (_tmp, fs) = make_test_fs();
    let result = fs.write_string("outside.txt", "bad");
    assert!(result.is_err());
}

#[test]
fn file_handle_write_outside_save_rejected() {
    let (_tmp, fs) = make_test_fs();
    let result = FileHandle::open(&fs, "outside.txt", FileMode::Write);
    assert!(result.is_err());
}

// ── Append creates and appends ───────────────────────────────────

#[test]
fn append_creates_and_appends() {
    let (_tmp, fs) = make_test_fs();

    fs.append_string("save/append.txt", "first\n").unwrap();
    fs.append_string("save/append.txt", "second\n").unwrap();

    let content = fs.read_string("save/append.txt").unwrap();
    assert_eq!(content, "first\nsecond\n");
}

#[test]
fn file_handle_append_mode() {
    let (_tmp, fs) = make_test_fs();

    let mut wh = FileHandle::open(&fs, "save/fh_append.txt", FileMode::Append).unwrap();
    wh.write(b"one").unwrap();
    wh.close().unwrap();

    let mut wh = FileHandle::open(&fs, "save/fh_append.txt", FileMode::Append).unwrap();
    wh.write(b"two").unwrap();
    wh.close().unwrap();

    let content = fs.read_string("save/fh_append.txt").unwrap();
    assert_eq!(content, "onetwo");
}

// ── Identity get/set ─────────────────────────────────────────────

#[test]
fn identity_get_set() {
    let (_tmp, mut fs) = make_test_fs();
    assert_eq!(fs.get_identity(), "");
    fs.set_identity("my_game");
    assert_eq!(fs.get_identity(), "my_game");
}

// ── isFile / isDirectory correctness ─────────────────────────────

#[test]
fn is_file_and_is_directory() {
    let (tmp, fs) = make_test_fs();
    std::fs::write(tmp.path().join("save/a_file.txt"), "data").unwrap();

    assert!(fs.is_file("save/a_file.txt"));
    assert!(!fs.is_directory("save/a_file.txt"));
    assert!(fs.is_directory("save"));
    assert!(!fs.is_file("save"));
    assert!(!fs.is_file("nonexistent"));
    assert!(!fs.is_directory("nonexistent"));
}

// ── Path utility functions ───────────────────────────────────────

#[test]
fn get_source_returns_base_dir() {
    let (tmp, fs) = make_test_fs();
    let expected = tmp.path().to_string_lossy().to_string();
    assert_eq!(fs.get_source(), expected);
}

#[test]
fn get_save_directory_returns_save_path() {
    let (tmp, fs) = make_test_fs();
    let expected = tmp.path().join("save");
    assert_eq!(fs.get_save_directory(), expected);
}

#[test]
fn get_working_directory_returns_string() {
    let result = GameFS::get_working_directory();
    assert!(result.is_ok());
    assert!(!result.unwrap().is_empty());
}

#[test]
fn get_user_directory_returns_non_empty() {
    let user_dir = GameFS::get_user_directory();
    assert!(!user_dir.is_empty());
}

// ── FileHandle closed mode ───────────────────────────────────────

#[test]
fn file_handle_closed_mode_rejected() {
    let (_tmp, fs) = make_test_fs();
    let result = FileHandle::open(&fs, "save/test.txt", FileMode::Closed);
    assert!(result.is_err());
}

#[test]
fn file_handle_operations_after_close_rejected() {
    let (_tmp, fs) = make_test_fs();

    let mut wh = FileHandle::open(&fs, "save/close_test.txt", FileMode::Write).unwrap();
    wh.write(b"data").unwrap();
    wh.close().unwrap();

    // Write after close should fail
    assert!(wh.write(b"more").is_err());
}
