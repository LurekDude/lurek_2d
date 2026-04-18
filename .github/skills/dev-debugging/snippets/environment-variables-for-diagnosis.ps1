# Show all Lurek2D log output (info + debug + trace)
$env:RUST_LOG = "lurek2d=debug"
cargo run -- content/demos/hello_world

# Show only engine startup/shutdown lifecycle events
$env:RUST_LOG = "lurek2d=info"

# Show wgpu validation errors (GPU-related crashes)
$env:RUST_LOG = "wgpu_core=warn,wgpu_hal=warn,lurek2d=debug"

# Full panic backtrace (file + line for every frame)
$env:RUST_BACKTRACE = "1"

# Full backtrace WITH source lines (requires debug symbols)
$env:RUST_BACKTRACE = "full"

# Force a specific GPU backend (useful to isolate driver bugs)
$env:WGPU_BACKEND = "vulkan"   # or "dx12", "metal", "gl"
$env:WGPU_ADAPTER_NAME = "Intel"   # prefer Intel iGPU when multiple adapters present

# Disable JIT compilation (fall back to LuaJIT interpreter — slower but stable)
# Set inside Lua: jit.off()
