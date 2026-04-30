//! Tests for the filesystem module.

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

    #[test]
    fn poll_nonexistent_no_change_on_second_poll() {
        let mut w = FileWatcher::new();
        w.watch("does_not_exist_xyz_abc.lua");
        // Both polls see mtime=None → no change
        let changed = w.poll();
        assert!(
            changed.is_empty(),
            "nonexistent file should not be 'changed'"
        );
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
    fn read_string_returns_contents() {
        let dir = make_temp_game("read_str");
        std::fs::write(dir.join("hello.txt"), "world").unwrap();
        let fs = GameFS::new(&dir);
        assert_eq!(fs.read_string("hello.txt").unwrap(), "world");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn read_string_rejects_path_traversal() {
        let dir = make_temp_game("traversal");
        let fs = GameFS::new(&dir);
        let result = fs.read_string("../../../etc/passwd");
        assert!(result.is_err());
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
    fn write_string_restricted_to_save_dir() {
        let dir = make_temp_game("write_save");
        let fs = GameFS::new(&dir);
        // Writing outside save/ should fail
        let result = fs.write_string("outside.txt", "data");
        assert!(result.is_err());
        // Writing inside save/ should succeed
        fs.write_string("save/test.txt", "hello").unwrap();
        let content = std::fs::read_to_string(dir.join("save/test.txt")).unwrap();
        assert_eq!(content, "hello");
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
    fn exists_checks_file_presence() {
        let dir = make_temp_game("exists");
        std::fs::write(dir.join("present.txt"), "x").unwrap();
        let fs = GameFS::new(&dir);
        assert!(fs.exists("present.txt"));
        assert!(!fs.exists("absent.txt"));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn is_file_and_is_directory() {
        let dir = make_temp_game("is_file_dir");
        std::fs::write(dir.join("f.txt"), "data").unwrap();
        std::fs::create_dir_all(dir.join("subdir")).unwrap();
        let fs = GameFS::new(&dir);
        assert!(fs.is_file("f.txt"));
        assert!(!fs.is_file("subdir"));
        assert!(fs.is_directory("subdir"));
        assert!(!fs.is_directory("f.txt"));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn list_returns_entry_names() {
        let dir = make_temp_game("list");
        std::fs::write(dir.join("a.txt"), "").unwrap();
        std::fs::write(dir.join("b.txt"), "").unwrap();
        let fs = GameFS::new(&dir);
        let items = fs.list(".").unwrap();
        assert!(items.contains(&"a.txt".to_string()));
        assert!(items.contains(&"b.txt".to_string()));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn get_directory_items_returns_sorted() {
        let dir = make_temp_game("sorted_items");
        std::fs::write(dir.join("c.txt"), "").unwrap();
        std::fs::write(dir.join("a.txt"), "").unwrap();
        std::fs::write(dir.join("b.txt"), "").unwrap();
        let fs = GameFS::new(&dir);
        let items = fs.get_directory_items(".").unwrap();
        // Items should be sorted; filter to just .txt files to ignore the save/ dir
        let filtered: Vec<_> = items
            .iter()
            .filter(|i| i.ends_with(".txt"))
            .cloned()
            .collect();
        assert_eq!(filtered, vec!["a.txt", "b.txt", "c.txt"]);
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
    fn read_lines_splits_on_newline() {
        let dir = make_temp_game("read_lines");
        std::fs::write(dir.join("lines.txt"), "one\ntwo\nthree").unwrap();
        let fs = GameFS::new(&dir);
        let lines = fs.read_lines("lines.txt").unwrap();
        assert_eq!(lines, vec!["one", "two", "three"]);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn append_string_adds_to_file() {
        let dir = make_temp_game("append");
        let fs = GameFS::new(&dir);
        fs.write_string("save/log.txt", "first\n").unwrap();
        fs.append_string("save/log.txt", "second\n").unwrap();
        let content = std::fs::read_to_string(dir.join("save/log.txt")).unwrap();
        assert_eq!(content, "first\nsecond\n");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn remove_file_in_save() {
        let dir = make_temp_game("remove");
        let fs = GameFS::new(&dir);
        fs.write_string("save/del.txt", "delete me").unwrap();
        assert!(dir.join("save/del.txt").exists());
        fs.remove("save/del.txt").unwrap();
        assert!(!dir.join("save/del.txt").exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn get_info_returns_file_metadata() {
        let dir = make_temp_game("info");
        std::fs::write(dir.join("data.txt"), "12345").unwrap();
        let fs = GameFS::new(&dir);
        let info = fs.get_info("data.txt").unwrap();
        assert_eq!(info.file_type, FileType::File);
        assert_eq!(info.size, 5);
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
    fn mount_rejects_path_traversal() {
        let dir = make_temp_game("mount_trav");
        let mut fs = GameFS::new(&dir);
        let result = fs.mount("../outside", "/hack");
        assert!(result.is_err());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn unmount_returns_false_for_unknown() {
        let dir = make_temp_game("unmount");
        let mut fs = GameFS::new(&dir);
        assert!(!fs.unmount("/nonexistent"));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn identity_get_set() {
        let dir = make_temp_game("identity");
        let mut fs = GameFS::new(&dir);
        assert_eq!(fs.get_identity(), "");
        fs.set_identity("my_game");
        assert_eq!(fs.get_identity(), "my_game");
        let _ = std::fs::remove_dir_all(&dir);
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
    fn open_read_and_read_all() {
        let (dir, fs) = make_temp_game("read_all");
        std::fs::write(dir.join("test.txt"), "hello world").unwrap();
        let mut fh = FileHandle::open(&fs, "test.txt", FileMode::Read).unwrap();
        let data = fh.read(None).unwrap();
        assert_eq!(data, b"hello world");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn open_read_partial() {
        let (dir, fs) = make_temp_game("read_partial");
        std::fs::write(dir.join("data.txt"), "abcdefgh").unwrap();
        let mut fh = FileHandle::open(&fs, "data.txt", FileMode::Read).unwrap();
        let data = fh.read(Some(3)).unwrap();
        assert_eq!(data, b"abc");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn open_write_creates_file() {
        let (dir, fs) = make_temp_game("write_create");
        let mut fh = FileHandle::open(&fs, "save/out.txt", FileMode::Write).unwrap();
        fh.write(b"written").unwrap();
        fh.close().unwrap();
        let content = std::fs::read_to_string(dir.join("save/out.txt")).unwrap();
        assert_eq!(content, "written");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn open_append_adds_to_file() {
        let (dir, fs) = make_temp_game("append");
        std::fs::write(dir.join("save/log.txt"), "first").unwrap();
        let mut fh = FileHandle::open(&fs, "save/log.txt", FileMode::Append).unwrap();
        fh.write(b"second").unwrap();
        fh.close().unwrap();
        let content = std::fs::read_to_string(dir.join("save/log.txt")).unwrap();
        assert_eq!(content, "firstsecond");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn read_line_returns_lines_and_eof() {
        let (dir, fs) = make_temp_game("readline");
        std::fs::write(dir.join("lines.txt"), "line1\nline2\n").unwrap();
        let mut fh = FileHandle::open(&fs, "lines.txt", FileMode::Read).unwrap();
        assert_eq!(fh.read_line().unwrap(), Some("line1".to_string()));
        assert_eq!(fh.read_line().unwrap(), Some("line2".to_string()));
        assert_eq!(fh.read_line().unwrap(), None); // EOF
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn seek_and_tell() {
        let (dir, fs) = make_temp_game("seek_tell");
        std::fs::write(dir.join("data.txt"), "abcdefgh").unwrap();
        let mut fh = FileHandle::open(&fs, "data.txt", FileMode::Read).unwrap();
        assert_eq!(fh.tell().unwrap(), 0);
        fh.seek(4).unwrap();
        assert_eq!(fh.tell().unwrap(), 4);
        let data = fh.read(Some(2)).unwrap();
        assert_eq!(data, b"ef");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn get_size_returns_file_length() {
        let (dir, fs) = make_temp_game("size");
        std::fs::write(dir.join("sized.txt"), "12345").unwrap();
        let fh = FileHandle::open(&fs, "sized.txt", FileMode::Read).unwrap();
        assert_eq!(fh.get_size(), 5);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn get_mode_returns_open_mode() {
        let (dir, fs) = make_temp_game("mode");
        std::fs::write(dir.join("m.txt"), "x").unwrap();
        let fh = FileHandle::open(&fs, "m.txt", FileMode::Read).unwrap();
        assert_eq!(fh.get_mode(), FileMode::Read);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn close_sets_closed_mode() {
        let (dir, fs) = make_temp_game("close");
        std::fs::write(dir.join("c.txt"), "x").unwrap();
        let mut fh = FileHandle::open(&fs, "c.txt", FileMode::Read).unwrap();
        fh.close().unwrap();
        assert_eq!(fh.get_mode(), FileMode::Closed);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn close_is_idempotent() {
        let (dir, fs) = make_temp_game("close_idem");
        std::fs::write(dir.join("d.txt"), "x").unwrap();
        let mut fh = FileHandle::open(&fs, "d.txt", FileMode::Read).unwrap();
        fh.close().unwrap();
        fh.close().unwrap(); // second close is a no-op
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn is_eof_at_end_of_file() {
        let (dir, fs) = make_temp_game("eof");
        std::fs::write(dir.join("eof.txt"), "ab").unwrap();
        let mut fh = FileHandle::open(&fs, "eof.txt", FileMode::Read).unwrap();
        assert!(!fh.is_eof().unwrap());
        fh.read(None).unwrap(); // consume all bytes
        assert!(fh.is_eof().unwrap());
        let _ = std::fs::remove_dir_all(&dir);
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

// ── reject_traversal (via GameFS) ─────────────────────────────────────────

mod reject_traversal_tests {
    use lurek2d::filesystem::GameFS;
    

    fn make_vfs() -> GameFS {
        let base = std::env::temp_dir().join("lurek_traversal_test");
        std::fs::create_dir_all(&base).ok();
        GameFS::new(base)
    }

    #[test]
    fn list_with_dotdot_returns_error() {
        let vfs = make_vfs();
        let result = vfs.list_recursive("../");
        assert!(result.is_err(), "list_recursive with '../' should error");
    }

    #[test]
    fn list_with_double_dotdot_returns_error() {
        let vfs = make_vfs();
        let result = vfs.list_recursive("save/../..");
        assert!(
            result.is_err(),
            "list_recursive with 'save/../..' should error"
        );
    }

    #[test]
    fn list_valid_path_does_not_error_on_empty_dir() {
        let base = std::env::temp_dir().join("lurek_traversal_test");
        let sub = base.join("sub");
        std::fs::create_dir_all(&sub).ok();
        let vfs = GameFS::new(base.clone());
        let result = vfs.list_recursive("sub");
        assert!(result.is_ok(), "valid path should succeed");
        std::fs::remove_dir_all(&sub).ok();
    }
}

mod stat_tests {
    use lurek2d::filesystem::GameFS;

    #[test]
    fn stat_returns_size_for_existing_file() {
        let base = std::env::temp_dir().join("lurek_stat_test");
        std::fs::create_dir_all(&base).ok();
        let vfs = GameFS::new(base.clone());
        // write file first
        std::fs::write(base.join("a.txt"), b"hello").unwrap();
        let (size, is_file, is_dir) = vfs.stat("a.txt").unwrap();
        assert_eq!(5, size);
        assert!(is_file);
        assert!(!is_dir);
        std::fs::remove_dir_all(&base).ok();
    }

    #[test]
    fn stat_rejects_path_traversal() {
        let base = std::env::temp_dir().join("lurek_stat_trav");
        std::fs::create_dir_all(&base).ok();
        let vfs = GameFS::new(base.clone());
        let result = vfs.stat("../../etc/passwd");
        assert!(result.is_err(), "traversal should be rejected");
        std::fs::remove_dir_all(&base).ok();
    }
}

mod create_temp_file_tests {
    use lurek2d::filesystem::GameFS;

    #[test]
    fn create_temp_file_returns_path_under_save() {
        let base = std::env::temp_dir().join("lurek_tmp_test");
        std::fs::create_dir_all(base.join("save")).ok();
        let vfs = GameFS::new(base.clone());
        let path = vfs.create_temp_file("pfx_").unwrap();
        assert!(path.starts_with("save/"), "path={path}");
        std::fs::remove_dir_all(&base).ok();
    }

    #[test]
    fn two_create_temp_file_calls_differ() {
        let base = std::env::temp_dir().join("lurek_tmp_diff");
        std::fs::create_dir_all(base.join("save")).ok();
        let vfs = GameFS::new(base.clone());
        let a = vfs.create_temp_file("t_").unwrap();
        let b = vfs.create_temp_file("t_").unwrap();
        assert_ne!(a, b, "successive temp files must be unique");
        std::fs::remove_dir_all(&base).ok();
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
