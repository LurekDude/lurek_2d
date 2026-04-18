$env:WGPU_BACKEND = "vulkan"   # force backend (optional)
$env:RUST_LOG = "wgpu_core=warn,wgpu_hal=warn"
cargo run -- content/demos/hello_world
