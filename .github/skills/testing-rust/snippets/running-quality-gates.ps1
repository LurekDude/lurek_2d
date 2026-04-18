cargo test                          # all tests — must exit 0
cargo test --test <module>_tests    # one Rust file
cargo test lua_test_<module>        # one Lua unit test dispatch
cargo clippy -- -D warnings         # lint — must exit 0
cargo fmt --check                   # format check
