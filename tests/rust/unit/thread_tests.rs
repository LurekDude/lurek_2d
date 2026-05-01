//! INTERNAL ONLY: public `lurek.thread.*` behavior is covered primarily by
//! `tests/lua/unit/test_thread_unit.lua` plus stress/integration suites.
//!
//! This Rust file keeps worker-VM and pool internals that are awkward to prove
//! through the Lua layer, while removing duplicated checks for channel basics.

// ── channel ───────────────────────────────────────────────────────────────────

mod channel_tests {
    use lurek2d::thread::channel::{Channel, ChannelValue};

    // ── Channel basics ────────────────────────────────────────────────────

    #[test]
    fn named_channel_has_name() {
        let ch = Channel::named("test-ch".to_string());
        assert_eq!(ch.name(), Some("test-ch"));
    }

    #[test]
    fn unnamed_channel_has_no_name() {
        let ch = Channel::new();
        assert!(ch.name().is_none());
    }

    // ── Push / Pop ────────────────────────────────────────────────────────

    #[test]
    fn push_returns_monotonic_ids() {
        let ch = Channel::new();
        let id1 = ch.push(ChannelValue::Nil);
        let id2 = ch.push(ChannelValue::Nil);
        assert!(id2 > id1);
    }

    // ── ChannelValue clone ────────────────────────────────────────────────

    #[test]
    fn channel_value_clone_roundtrip() {
        let original = ChannelValue::Table(vec![
            (ChannelValue::String("key".into()), ChannelValue::Number(42.0)),
        ]);
        let cloned = original.clone();
        match cloned {
            ChannelValue::Table(pairs) => {
                assert_eq!(pairs.len(), 1);
            }
            _ => panic!("expected Table"),
        }
    }

    #[test]
    fn channel_value_bytes() {
        let ch = Channel::new();
        ch.push(ChannelValue::Bytes(vec![0xDE, 0xAD]));
        match ch.pop() {
            Some(ChannelValue::Bytes(b)) => assert_eq!(b, vec![0xDE, 0xAD]),
            other => panic!("expected Bytes, got {:?}", other),
        }
    }
}

// ── worker ────────────────────────────────────────────────────────────────────

mod worker_tests {
    use std::collections::HashMap;
    use std::sync::{Arc, Mutex};

    use lurek2d::thread::channel::{Channel, ChannelValue};
    use lurek2d::thread::worker::{LuaThread, ThreadState};

    fn empty_channels() -> Arc<Mutex<HashMap<String, Arc<Channel>>>> {
        Arc::new(Mutex::new(HashMap::new()))
    }

    #[test]
    fn new_thread_starts_in_pending_state() {
        let t = LuaThread::new("return 1".into(), empty_channels());
        assert!(!t.is_running());
        assert!(t.get_error().is_none());
    }

    #[test]
    fn start_transitions_to_running_then_completed() {
        let mut t = LuaThread::new("-- noop".into(), empty_channels());
        assert!(t.start(vec![]).is_ok());
        t.wait();
        // After wait, thread should no longer be running
        assert!(!t.is_running());
        assert!(t.get_error().is_none());
    }

    #[test]
    fn start_already_running_returns_error() {
        let channels = empty_channels();
        // Use a script that blocks briefly so the thread is still running
        // when we try to start again.
        let ch = Channel::named("__block".to_string());
        channels.lock().unwrap().insert("__block".into(), ch.clone());
        let mut t = LuaThread::new(
            r#"lurek.thread.getChannel("__block"):demand()"#.into(),
            channels,
        );
        assert!(t.start(vec![]).is_ok());
        // Attempting a second start should fail
        let result = t.start(vec![]);
        assert!(result.is_err());
        // Unblock the worker so the test can clean up
        ch.push(ChannelValue::Nil);
        t.wait();
    }

    #[test]
    fn lua_error_captured_in_thread_state() {
        let mut t = LuaThread::new("error('boom')".into(), empty_channels());
        assert!(t.start(vec![]).is_ok());
        t.wait();
        let err = t.get_error();
        assert!(err.is_some());
        assert!(err.unwrap().contains("boom"));
    }

    #[test]
    fn args_passed_to_worker_vm() {
        let channels = empty_channels();
        let result_ch = Channel::named("__result".to_string());
        channels
            .lock()
            .unwrap()
            .insert("__result".into(), result_ch.clone());

        let code = r#"
            local ch = lurek.thread.getChannel("__result")
            ch:push(arg[1])
        "#;
        let mut t = LuaThread::new(code.into(), channels);
        assert!(t.start(vec![ChannelValue::Number(99.0)]).is_ok());
        t.wait();

        let val = result_ch.pop();
        assert!(val.is_some());
        match val.unwrap() {
            ChannelValue::Number(n) => assert!((n - 99.0).abs() < f64::EPSILON),
            other => panic!("expected Number(99.0), got {:?}", other),
        }
    }

    #[test]
    fn wait_on_unstarted_thread_is_noop() {
        let mut t = LuaThread::new("return 1".into(), empty_channels());
        t.wait(); // should not panic or block
    }

    #[test]
    fn thread_state_variants_eq() {
        assert_eq!(ThreadState::Pending, ThreadState::Pending);
        assert_eq!(ThreadState::Running, ThreadState::Running);
        assert_eq!(ThreadState::Completed, ThreadState::Completed);
        assert_ne!(ThreadState::Pending, ThreadState::Running);
        assert_eq!(
            ThreadState::Error("x".into()),
            ThreadState::Error("x".into())
        );
    }
}

// ── pool ──────────────────────────────────────────────────────────────────────

mod pool_tests {
    use lurek2d::thread::channel::ChannelValue;
    use lurek2d::thread::pool::ThreadPool;

    /// Minimal Lua script that reads one value from __pool_input and echoes
    /// it to __pool_output. The worker exits after processing one item.
    const ECHO_WORKER: &str = r#"
        local input  = lurek.thread.getChannel("__pool_input")
        local output = lurek.thread.getChannel("__pool_output")
        local val = input:demand()
        output:push(val)
    "#;

    #[test]
    fn pool_size_matches_requested() {
        let pool = ThreadPool::new(3, ECHO_WORKER.to_string());
        assert_eq!(pool.size(), 3);
    }

    #[test]
    fn submit_and_collect_roundtrip() {
        let mut pool = ThreadPool::new(1, ECHO_WORKER.to_string());
        pool.submit(ChannelValue::Number(42.0));
        pool.join();
        let result = pool.collect();
        assert!(result.is_some());
        match result.unwrap() {
            ChannelValue::Number(n) => assert!((n - 42.0).abs() < f64::EPSILON),
            other => panic!("expected Number(42.0), got {:?}", other),
        }
    }

    #[test]
    fn collect_returns_none_when_empty() {
        let pool = ThreadPool::new(1, ECHO_WORKER.to_string());
        // No submit → no output yet (workers block on demand)
        assert!(pool.collect().is_none());
    }

    #[test]
    fn input_output_channels_accessible() {
        let pool = ThreadPool::new(1, ECHO_WORKER.to_string());
        // Channels should exist and be empty initially
        assert_eq!(pool.input.get_count(), 0);
        assert_eq!(pool.output.get_count(), 0);
    }
}

// ── promise ───────────────────────────────────────────────────────────────────

mod promise_tests {
    use lurek2d::thread::promise::PromiseState;

    #[test]
    fn promise_state_pending_is_default() {
        let state = PromiseState::Pending;
        assert_eq!(state, PromiseState::Pending);
    }

    #[test]
    fn promise_state_done_eq() {
        assert_eq!(PromiseState::Done, PromiseState::Done);
        assert_ne!(PromiseState::Done, PromiseState::Pending);
    }

    #[test]
    fn promise_state_error_carries_message() {
        let state = PromiseState::Error("runtime error".into());
        match state {
            PromiseState::Error(msg) => assert_eq!(msg, "runtime error"),
            _ => panic!("expected Error variant"),
        }
    }

    #[test]
    fn promise_state_clone() {
        let original = PromiseState::Error("oops".into());
        let cloned = original.clone();
        assert_eq!(cloned, PromiseState::Error("oops".into()));
    }
}
