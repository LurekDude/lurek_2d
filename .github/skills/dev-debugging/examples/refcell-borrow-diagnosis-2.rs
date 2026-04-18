// BAD: borrow held across a Lua call that also borrows
let state = self.state.borrow();      // borrow 1 starts
let val = state.something;
lua.call_function("callback", val)?;  // callback may also borrow_mut → PANIC
drop(state);                          // borrow 1 never reached
