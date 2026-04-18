// GOOD: clone the value out, release borrow, then call Lua
let val = {
    let state = self.state.borrow();   // borrow starts
    state.something.clone()             // extract value
};                                      // borrow ends HERE
lua.call_function("callback", val)?;   // safe — no active borrow
