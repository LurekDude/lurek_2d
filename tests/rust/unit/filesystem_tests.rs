//! INTERNAL ONLY: Rust-only tests for filesystem helpers that are not exposed as `lurek.filesystem.*`.
//!
//! Public `lurek.filesystem.*` behavior now lives in
//! `tests/lua/unit/test_filesystem_unit.lua`. The remaining Rust tests keep
//! watcher internals, low-level async loader behavior, ZIP helper details, and
//! a few non-Lua-facing helper invariants.

use lurek2d::filesystem::watcher::FileWatcher;
use lurek2d::filesystem::*;
use std::path::PathBuf;

// ── watcher ───────────────────────────────────────────────────────────────────

mod watcher_tests {
    use super::*;

    #[test]
    fn new_watcher_is_empty() {
        let w = FileWatcher::new();
        assert!(w.is_empty());
        assert_eq!(w.len(), 0);
    }

    #[test]
    fn watch_and_unwatch_len() {
        let mut w = FileWatcher::new();
        w.watch("some_file.txt");
        assert_eq!(w.len(), 1);
        assert!(w.is_watching("some_file.txt"));
        w.unwatch("some_file.txt");
        assert_eq!(w.len(), 0);
    }
}

// ── vfs (GameFS) ──────────────────────────────────────────────────────────────

mod vfs_tests {
    use super::*;

    /// Create a temporary game directory with a `save/` subdirectory.
    fn make_temp_game(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("luna_vfs_test_{}", name));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(dir.join("save")).unwrap();
        dir
    }

    #[test]
    fn new_creates_gamefs_with_base_dir() {
        let dir = make_temp_game("new");
        let fs = GameFS::new(&dir);
        assert_eq!(fs.base_dir(), dir.as_path());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn read_bytes_returns_raw_content() {
        let dir = make_temp_game("read_bytes");
        std::fs::write(dir.join("bin.dat"), [0xFF, 0x00, 0xAB]).unwrap();
        let fs = GameFS::new(&dir);
        assert_eq!(fs.read_bytes("bin.dat").unwrap(), vec![0xFF, 0x00, 0xAB]);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn resolve_save_path_rejects_outside_save() {
        let dir = make_temp_game("resolve_save");
        let fs = GameFS::new(&dir);
        assert!(fs.resolve_save_path("outside.txt").is_err());
        assert!(fs.resolve_save_path("save/ok.txt").is_ok());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn resolve_save_path_rejects_dotdot() {
        let dir = make_temp_game("save_dotdot");
        let fs = GameFS::new(&dir);
        let result = fs.resolve_save_path("save/../outside.txt");
        assert!(result.is_err());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn write_bytes_to_save_dir() {
        let dir = make_temp_game("write_bytes");
        let fs = GameFS::new(&dir);
        fs.write_bytes("save/data.bin", &[1, 2, 3]).unwrap();
        let bytes = std::fs::read(dir.join("save/data.bin")).unwrap();
        assert_eq!(bytes, vec![1, 2, 3]);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn filetype_as_str() {
        assert_eq!(FileType::File.as_str(), "file");
        assert_eq!(FileType::Directory.as_str(), "directory");
        assert_eq!(FileType::Symlink.as_str(), "symlink");
        assert_eq!(FileType::Other.as_str(), "other");
    }

    #[test]
    fn get_save_directory_is_under_base() {
        let dir = make_temp_game("save_dir");
        let fs = GameFS::new(&dir);
        assert_eq!(fs.get_save_directory(), dir.join("save"));
        let _ = std::fs::remove_dir_all(&dir);
    }
}

// ── file_handle ───────────────────────────────────────────────────────────────

mod file_handle_tests {
    use super::*;

    /// Create a temp game directory with a `save/` subdirectory and return both
    /// the path and a `GameFS` rooted there.
    fn make_temp_game(name: &str) -> (PathBuf, GameFS) {
        let dir = std::env::temp_dir().join(format!("luna_fh_test_{}", name));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(dir.join("save")).unwrap();
        let fs = GameFS::new(&dir);
        (dir, fs)
    }

    #[test]
    fn parse_mode_valid_strings() {
        assert_eq!(FileMode::parse_mode("r").unwrap(), FileMode::Read);
        assert_eq!(FileMode::parse_mode("w").unwrap(), FileMode::Write);
        assert_eq!(FileMode::parse_mode("a").unwrap(), FileMode::Append);
    }

    #[test]
    fn parse_mode_invalid_string() {
        assert!(FileMode::parse_mode("x").is_err());
        assert!(FileMode::parse_mode("rw").is_err());
    }

    #[test]
    fn as_str_returns_expected() {
        assert_eq!(FileMode::Read.as_str(), "r");
        assert_eq!(FileMode::Write.as_str(), "w");
        assert_eq!(FileMode::Append.as_str(), "a");
        assert_eq!(FileMode::Closed.as_str(), "c");
    }

    #[test]
    fn open_closed_mode_fails() {
        let (dir, _fs) = make_temp_game("closed_open");
        let fs2 = GameFS::new(&dir);
        let result = FileHandle::open(&fs2, "any.txt", FileMode::Closed);
        assert!(result.is_err());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn get_path_returns_logical_path() {
        let (dir, fs) = make_temp_game("path");
        std::fs::write(dir.join("p.txt"), "x").unwrap();
        let fh = FileHandle::open(&fs, "p.txt", FileMode::Read).unwrap();
        assert_eq!(fh.get_path(), "p.txt");
        let _ = std::fs::remove_dir_all(&dir);
    }
}

// ── file_data ─────────────────────────────────────────────────────────────────

mod file_data_tests {
    use super::*;

    #[test]
    fn new_stores_path_and_bytes() {
        let fd = FileData::new("assets/hero.png".into(), vec![1, 2, 3]);
        assert_eq!(fd.path, "assets/hero.png");
        assert_eq!(fd.bytes, vec![1, 2, 3]);
    }

    #[test]
    fn len_and_is_empty() {
        let empty = FileData::new("empty".into(), vec![]);
        assert_eq!(empty.len(), 0);
        assert!(empty.is_empty());

        let non_empty = FileData::new("data".into(), vec![0xFF]);
        assert_eq!(non_empty.len(), 1);
        assert!(!non_empty.is_empty());
    }

    #[test]
    fn as_str_valid_utf8() {
        let fd = FileData::new("t.txt".into(), b"hello world".to_vec());
        assert_eq!(fd.as_str().unwrap(), "hello world");
    }

    #[test]
    fn as_str_invalid_utf8() {
        let fd = FileData::new("bin".into(), vec![0xFF, 0xFE]);
        assert!(fd.as_str().is_err());
    }
}

// ── async_loader ──────────────────────────────────────────────────────────────

mod async_loader_tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn load_existing_file() {
        let dir = std::env::temp_dir().join("luna_async_test_load");
        std::fs::create_dir_all(&dir).unwrap();
        let file = dir.join("hello.txt");
        let mut f = std::fs::File::create(&file).unwrap();
        f.write_all(b"hello async").unwrap();
        drop(f);

        let loader = AsyncLoader::new();
        let handle = loader.request_load(file.clone());

        // Spin-poll with a cap to avoid hanging tests.
        for _ in 0..1000 {
            if let LoadStatus::Done(result) = loader.poll(handle) {
                match result {
                    LoadResult::Ready(bytes) => {
                        assert_eq!(bytes, b"hello async");
                        std::fs::remove_dir_all(&dir).ok();
                        return;
                    }
                    LoadResult::Error(e) => panic!("unexpected error: {}", e),
                }
            }
            std::thread::sleep(std::time::Duration::from_millis(1));
        }
        panic!("load did not complete within timeout");
    }

    #[test]
    fn load_missing_file() {
        let loader = AsyncLoader::new();
        let handle = loader.request_load(PathBuf::from("/nonexistent/file.txt"));

        for _ in 0..1000 {
            if let LoadStatus::Done(result) = loader.poll(handle) {
                match result {
                    LoadResult::Error(_) => return, // expected
                    LoadResult::Ready(_) => panic!("should have failed"),
                }
            }
            std::thread::sleep(std::time::Duration::from_millis(1));
        }
        panic!("load did not complete within timeout");
    }

    #[test]
    fn poll_returns_done_once() {
        let dir = std::env::temp_dir().join("luna_async_test_once");
        std::fs::create_dir_all(&dir).unwrap();
        let file = dir.join("once.txt");
        std::fs::write(&file, b"data").unwrap();

        let loader = AsyncLoader::new();
        let handle = loader.request_load(file);

        // Wait for completion
        loop {
            if let LoadStatus::Done(_) = loader.poll(handle) {
                break;
            }
            std::thread::sleep(std::time::Duration::from_millis(1));
        }

        // Second poll should return Pending (result consumed)
        match loader.poll(handle) {
            LoadStatus::Pending => {} // correct
            LoadStatus::Done(_) => panic!("result returned twice"),
        }

        std::fs::remove_dir_all(&dir).ok();
    }
}

// ── zip_mount ─────────────────────────────────────────────────────────────

mod zip_mount_tests {
    use lurek2d::filesystem::zip_mount::*;

    #[test]
    fn normalise_collapses_slashes() {
        assert_eq!(normalise("//foo//bar/"), "foo/bar");
    }

    #[test]
    fn is_traversal_detects_dotdot() {
        assert!(is_traversal("../secret"));
    }

    #[test]
    fn is_traversal_allows_normal_path() {
        assert!(!is_traversal("assets/images/hero.png"));
    }
}
