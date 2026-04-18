# FASTEST: type-check only — no compilation, ~2-5s incremental
cargo check

# Build debug binary (incremental, ~5-15s after first build)
cargo build

# Run a demo directly (builds if needed)
cargo run -- content/demos/hello_world

# Build release binary (full optimisation, ~60-120s first build)
cargo build --release

# Run release binary
cargo run --release -- content/demos/hello_world

# Build distribution binary (fat LTO, ~90-180s)
cargo build --profile dist
