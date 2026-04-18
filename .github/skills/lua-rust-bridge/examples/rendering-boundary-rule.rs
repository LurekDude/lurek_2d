// CORRECT — queue a draw command
let cmd = RenderCommand::Rectangle { ... };
state.borrow_mut().draw_commands.push(cmd);

// WRONG — never call wgpu render methods inside a Lua closure
state.borrow().gpu_renderer.render(...); // compile error anyway, but conceptually wrong
