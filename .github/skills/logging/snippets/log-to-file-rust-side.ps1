# Redirect both stdout and stderr to a file
$env:RUST_LOG = "lurek2d=debug"
cargo run -- content/demos/hello_world 2>&1 | Tee-Object logs/run.log
