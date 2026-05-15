//! INTERNAL ONLY: renderer command generation for postfx stacks is covered here because Lua only
//! queues commands indirectly through shared runtime state and cannot assert raw `RenderCommand`
//! payloads one-to-one.

use lurek2d::effect::stack::PostFxStack;
use lurek2d::render::renderer::RenderCommand;

#[test]
fn empty_stack_produces_no_commands() {
    let stack = PostFxStack::new(800, 600);
    let cmds = stack.generate_render_commands(1);
    assert!(cmds.is_empty());
}

#[test]
fn stack_with_disabled_effects_produces_no_commands() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.set_enabled(0, false);
    let cmds = stack.generate_render_commands(1);
    assert!(cmds.is_empty());
}

#[test]
fn stack_with_enabled_effects_produces_three_commands() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    let cmds = stack.generate_render_commands(1);
    assert_eq!(cmds.len(), 3);
    assert!(matches!(cmds[0], RenderCommand::BeginPostFx { .. }));
    assert!(matches!(cmds[1], RenderCommand::EndPostFx { .. }));
    assert!(matches!(cmds[2], RenderCommand::ApplyPostFx { .. }));
}

#[test]
fn begin_capture_uses_stack_id() {
    let stack = PostFxStack::new(800, 600);
    let cmd = stack.begin_capture_command(42);
    if let RenderCommand::BeginPostFx { stack_id } = cmd {
        assert_eq!(stack_id, 42);
    } else {
        panic!("Expected BeginPostFx");
    }
}
