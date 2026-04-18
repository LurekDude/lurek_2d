# See log output during a test run
$env:RUST_LOG = "lurek2d=debug"
cargo test --test math_tests -- --nocapture

# See log output from a Lua test
$env:RUST_LOG = "lurek2d=debug"
cargo test lua_test_math -- --nocapture
