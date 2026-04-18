# Show all output from lurek2d at info level and above
$env:RUST_LOG = "lurek2d=info"
cargo run -- content/demos/hello_world

# Show debug output from one module only
$env:RUST_LOG = "luna2d::graphics=debug"
cargo run -- content/demos/sprites

# Show debug from lurek2d, but silence wgpu noise
$env:RUST_LOG = "lurek2d=debug,wgpu_core=warn,wgpu_hal=warn"

# Show everything (very verbose � wgpu produces thousands of lines)
$env:RUST_LOG = "debug"

# Multiple targets at different levels
$env:RUST_LOG = "luna2d::physics=trace,luna2d::audio=debug,wgpu=error"

# Show nothing (silent mode)
$env:RUST_LOG = "error"
