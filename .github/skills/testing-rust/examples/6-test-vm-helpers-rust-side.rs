// Full VM with test framework loaded — use for Lua test files
fn create_test_vm() -> mlua::Lua { ... }

// Returns (Rc<RefCell<SharedState>>, Lua) for stateful Rust-side tests
fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) { ... }
