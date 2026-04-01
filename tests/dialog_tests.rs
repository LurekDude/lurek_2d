//! Integration tests for the dialog sequencer (`luna.dialog`).

use luna2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(
        SharedState::new(800, 600, "Test", PathBuf::from(".")),
    ));
    create_lua_vm(state).unwrap()
}

#[test]
fn dialog_new_sequencer() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        assert(seq:type() == "Sequencer", "type should be Sequencer, got " .. seq:type())
        assert(seq:typeOf("Object"), "should be Object")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_initial_state() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        assert(seq:getState() == "idle", "initial state should be idle, got " .. seq:getState())
        assert(not seq:isActive(), "should not be active initially")
        assert(not seq:isWaitingForChoice(), "should not be waiting for choice")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_load_and_start_say() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "Alice", text = "Hello world" }
        })
        seq:start()
        assert(seq:getState() == "typing", "state should be typing after start, got " .. seq:getState())
        assert(seq:currentSpeaker() == "Alice", "speaker should be Alice")
        assert(seq:currentText() == "Hello world", "text should be Hello world")
        assert(seq:isActive(), "should be active")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_set_speed() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:setSpeed(60)
        assert(math.abs(seq:getSpeed() - 60) < 0.01, "speed should be 60")
        seq:setSpeed(0)
        assert(math.abs(seq:getSpeed()) < 0.01, "speed should be 0")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_skip() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "Bob", text = "Long text here" }
        })
        seq:start()
        assert(seq:getState() == "typing", "should be typing")
        seq:skip()
        local revealed = seq:revealedText()
        assert(revealed == "Long text here", "revealed text should be full after skip, got: " .. revealed)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_advance_typing() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "NPC", text = "Hi" }
        })
        seq:start()
        assert(seq:getState() == "typing", "should be typing after start")
        seq:advance()
        assert(seq:getState() == "waiting", "advance during typing should skip to waiting, got " .. seq:getState())
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_advance_waiting_to_done() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "NPC", text = "Hi" }
        })
        seq:start()
        seq:advance() -- typing -> waiting
        assert(seq:getState() == "waiting", "should be waiting")
        seq:advance() -- waiting -> done (last node)
        assert(seq:getState() == "done", "should be done after last node, got " .. seq:getState())
        assert(not seq:isActive(), "should not be active when done")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_choice_node() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "choice", text = "Pick one:", options = {
                { label = "Option A" },
                { label = "Option B" },
            }}
        })
        seq:start()
        assert(seq:getState() == "choice", "should be in choice state, got " .. seq:getState())
        assert(seq:isWaitingForChoice(), "should be waiting for choice")
        assert(seq:getChoiceText() == "Pick one:", "choice text should match")
        local labels = seq:getChoiceLabels()
        assert(#labels == 2, "should have 2 labels")
        assert(labels[1] == "Option A", "first label should be Option A")
        assert(labels[2] == "Option B", "second label should be Option B")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_choose() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "choice", text = "Pick:", options = {
                { label = "A", branch = {
                    { type = "say", speaker = "NPC", text = "You chose A" }
                }},
                { label = "B", branch = {
                    { type = "say", speaker = "NPC", text = "You chose B" }
                }},
            }}
        })
        seq:start()
        assert(seq:getState() == "choice", "should be choice")
        seq:choose(1) -- pick option A
        -- After choosing, the branch is spliced in and we advance
        -- The sequencer should be on the branch node now
        local state = seq:getState()
        assert(state == "typing" or state == "waiting" or state == "done",
               "should have advanced into branch, got " .. state)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_wait_node() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "wait", time = 0.5 }
        })
        seq:start()
        assert(seq:getState() == "paused", "should be paused for wait node, got " .. seq:getState())
        -- Update with partial time
        seq:update(0.3)
        assert(seq:getState() == "paused", "should still be paused")
        -- Update past the wait time
        seq:update(0.3)
        -- After wait completes, should move to next (done since last node)
        assert(seq:getState() == "done", "should be done after wait completes, got " .. seq:getState())
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_call_node() {
    let lua = make_vm();
    lua.load(
        r#"
        local called = false
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "call", fn = function() called = true end }
        })
        seq:start()
        -- Call node should fire immediately and advance
        assert(called, "call callback should have been invoked")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_finished_state() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "Done" }
        })
        seq:start()
        seq:advance() -- typing -> waiting
        seq:advance() -- waiting -> done
        assert(seq:getState() == "done", "should be done")
        assert(not seq:isActive(), "should not be active when done")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_line_event() {
    let lua = make_vm();
    lua.load(
        r#"
        local fired_speaker = nil
        local fired_text = nil
        local seq = luna.dialog.newSequencer()
        seq:on("line", function(speaker, text)
            fired_speaker = speaker
            fired_text = text
        end)
        seq:load({
            { type = "say", speaker = "Eve", text = "Hi there" }
        })
        seq:start()
        assert(fired_speaker == "Eve", "line event should fire with speaker Eve, got " .. tostring(fired_speaker))
        assert(fired_text == "Hi there", "line event should fire with text")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_revealed_text() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:setSpeed(10) -- 10 chars/sec
        seq:load({
            { type = "say", speaker = "NPC", text = "Hello World" }
        })
        seq:start()
        -- Initially 0 chars revealed
        local r1 = seq:revealedText()
        assert(#r1 == 0 or #r1 < 11, "initially should have few chars revealed")
        -- Update for 0.5 sec = 5 chars
        seq:update(0.5)
        local r2 = seq:revealedText()
        assert(#r2 >= 4 and #r2 <= 6, "after 0.5s at 10cps should reveal ~5 chars, got " .. #r2)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_empty_script() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:load({})
        seq:start()
        assert(seq:getState() == "done", "empty script should go to done, got " .. seq:getState())
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_speed_zero_instant() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:setSpeed(0)
        seq:load({
            { type = "say", speaker = "NPC", text = "Instant" }
        })
        seq:start()
        -- Speed 0 means instant reveal, should go straight to waiting
        assert(seq:getState() == "waiting", "speed 0 should instantly reveal, got " .. seq:getState())
        assert(seq:revealedText() == "Instant", "full text should be revealed")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_off_event() {
    let lua = make_vm();
    lua.load(
        r#"
        local count = 0
        local seq = luna.dialog.newSequencer()
        seq:on("line", function() count = count + 1 end)
        seq:load({
            { type = "say", speaker = "A", text = "First" }
        })
        seq:start()
        assert(count == 1, "line event should fire once")
        seq:off("line")
        seq:advance() -- typing -> waiting
        seq:advance() -- waiting -> done
        -- Load and start new script
        seq:load({
            { type = "say", speaker = "B", text = "Second" }
        })
        seq:start()
        assert(count == 1, "after off, line event should not fire again, got " .. count)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_full_workflow() {
    let lua = make_vm();
    lua.load(
        r#"
        local seq = luna.dialog.newSequencer()
        seq:setSpeed(0) -- instant for testing
        seq:load({
            { type = "say", speaker = "Alice", text = "Hello" },
            { type = "say", speaker = "Bob", text = "Hi" },
        })
        seq:start()
        assert(seq:getState() == "waiting", "first say should be waiting (speed=0)")
        assert(seq:currentSpeaker() == "Alice", "first speaker Alice")
        seq:advance() -- waiting -> next node (Bob)
        assert(seq:getState() == "waiting", "second say should be waiting (speed=0)")
        assert(seq:currentSpeaker() == "Bob", "second speaker Bob")
        seq:advance() -- waiting -> done
        assert(seq:getState() == "done", "should be done after last node")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_finished_event() {
    let lua = make_vm();
    lua.load(
        r#"
        local finished = false
        local seq = luna.dialog.newSequencer()
        seq:setSpeed(0) -- instant
        seq:on("finished", function() finished = true end)
        seq:load({
            { type = "say", speaker = "A", text = "Done" }
        })
        seq:start()
        seq:advance() -- waiting -> done
        assert(finished, "finished event should fire when reaching done state")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn dialog_choice_event() {
    let lua = make_vm();
    lua.load(
        r#"
        local choice_fired = false
        local seq = luna.dialog.newSequencer()
        seq:on("choice", function() choice_fired = true end)
        seq:load({
            { type = "choice", text = "Pick:", options = {
                { label = "A" },
                { label = "B" },
            }}
        })
        seq:start()
        assert(choice_fired, "choice event should fire when entering choice state")
        "#,
    )
    .exec()
    .unwrap();
}
