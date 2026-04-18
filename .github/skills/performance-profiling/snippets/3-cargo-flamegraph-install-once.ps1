cargo install flamegraph       # one-time install

# Record a flame graph while running a demo:
cargo flamegraph -- content/demos/hello_world

# Output: flamegraph.svg — open in browser to navigate hot paths
