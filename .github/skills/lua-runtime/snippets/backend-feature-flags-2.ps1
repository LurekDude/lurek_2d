# Lua 5.4 (no LuaJIT, for CI or cross-compilation)
cargo build --no-default-features --features lua54
cargo test  --no-default-features --features lua54
