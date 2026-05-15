//! INTERNAL ONLY: public `lurek.repl.*` behavior is covered by the Lua-first
//! suite in `tests/lua/unit/test_repl_core_unit.lua`.
//!
//! The remaining Rust tests keep internal `ReplResult` and `ReplCommand`
//! variant contracts that are not directly observable through the Lua binding
//! surface.

use lurek2d::repl::{ReplCommand, ReplResult, ReplSession};

#[test]
fn eval_expression_returns_value_variant() {
    let lua = mlua::Lua::new();
    let mut session = ReplSession::new(8);

    let result = session.eval_line("2 + 3", &lua);

    assert_eq!(result, ReplResult::Value("5".to_string()));
}

#[test]
fn eval_statement_returns_ok_variant_and_keeps_lua_state() {
    let lua = mlua::Lua::new();
    let mut session = ReplSession::new(8);

    assert_eq!(session.eval_line("answer = 41", &lua), ReplResult::Ok);
    assert_eq!(
        session.eval_line("answer + 1", &lua),
        ReplResult::Value("42".to_string())
    );
}

#[test]
fn commands_return_internal_command_variants() {
    let lua = mlua::Lua::new();
    let mut session = ReplSession::new(8);

    assert_eq!(
        session.eval_line(":help", &lua),
        ReplResult::Command(ReplCommand::Help)
    );
    assert_eq!(
        session.eval_line(":quit", &lua),
        ReplResult::Command(ReplCommand::Quit)
    );
    assert_eq!(
        session.eval_line(":clear", &lua),
        ReplResult::Command(ReplCommand::Clear)
    );
    assert!(session.is_empty());
}

#[test]
fn load_command_returns_load_variant_for_valid_file() {
    let lua = mlua::Lua::new();
    let mut session = ReplSession::new(8);
    let dir = tempfile::tempdir().expect("tempdir");
    let file_path = dir.path().join("snippet.lua");
    std::fs::write(&file_path, "loaded_value = 19").expect("write snippet");

    let result = session.eval_line(&format!(":load {}", file_path.display()), &lua);

    assert_eq!(
        result,
        ReplResult::Command(ReplCommand::Load {
            path: file_path.display().to_string(),
        })
    );
}
