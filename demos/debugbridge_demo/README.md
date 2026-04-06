# Debug Bridge Demo

Demonstrates `luna.debugbridge`: a TCP-based debug server that allows external tools (telnet, netcat, custom editors) to query and control a running game.

## What It Demonstrates

- `luna.debugbridge.start()` — start the TCP debug server on a port
- `luna.debugbridge.stop()` — graceful shutdown
- JSON-RPC protocol: `{"id":1,"method":"ping"}` style requests
- Built-in methods: `ping`, `get_state`, `get_fps`, `set_value`
- Custom method registration: `luna.debugbridge.register("method", fn)`
- Handling disconnects and multiple simultaneous connections

## How to Run

```powershell
cargo run -- examples/debugbridge_demo
# Connect from another terminal:
# telnet 127.0.0.1 19740
# or: nc 127.0.0.1 19740
```

## Protocol

Send newline-terminated JSON-RPC:
```json
{"id":1,"method":"ping"}
{"id":2,"method":"get_state"}
```

## Notes

- Default port: `19740` (configurable)
- Not intended for production builds — disable in release builds
- Secure by binding to `127.0.0.1` only (no external network exposure)
