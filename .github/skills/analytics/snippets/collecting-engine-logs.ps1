# Record a full session with debug output
$env:RUST_LOG = "lurek2d=debug,wgpu_core=warn"
cargo run -- content/demos/my_game 2>&1 | Tee-Object logs/session.log
