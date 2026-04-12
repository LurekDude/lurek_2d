//! Integration tests for the Lurek2D threading module.

use lurek2d::thread::channel::{Channel, ChannelValue};
use lurek2d::thread::worker::LuaThread;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

// ── Channel basic tests ──────────────────────────────────────────────

#[test]
fn test_channel_push_pop() {
    let channel = Channel::new();
    channel.push(ChannelValue::Number(42.0));
    channel.push(ChannelValue::String("hello".into()));

    match channel.pop() {
        Some(ChannelValue::Number(n)) => assert!((n - 42.0).abs() < f64::EPSILON),
        other => panic!("Expected Number(42.0), got {:?}", other),
    }
    match channel.pop() {
        Some(ChannelValue::String(s)) => assert_eq!(s, "hello"),
        other => panic!("Expected String(\"hello\"), got {:?}", other),
    }
    assert!(channel.pop().is_none());
}

#[test]
fn test_channel_demand_timeout() {
    let channel = Channel::new();
    let result = channel.demand(Some(0.01));
    assert!(
        result.is_none(),
        "demand on empty channel should return None after timeout"
    );
}

#[test]
fn test_channel_named_shared() {
    let ch1 = Channel::named("shared".into());
    // Named channels have the same name
    assert_eq!(ch1.name(), Some("shared"));

    // Sharing via Arc: cloning the Arc gives the same underlying channel
    let ch2 = ch1.clone();
    ch1.push(ChannelValue::Number(99.0));
    match ch2.pop() {
        Some(ChannelValue::Number(n)) => assert!((n - 99.0).abs() < f64::EPSILON),
        other => panic!("Expected Number(99.0), got {:?}", other),
    }
}

#[test]
fn test_channel_value_types() {
    let channel = Channel::new();

    // Nil round-trip
    channel.push(ChannelValue::Nil);
    match channel.pop() {
        Some(ChannelValue::Nil) => {}
        other => panic!("Expected Nil, got {:?}", other),
    }

    // Bool round-trip
    channel.push(ChannelValue::Bool(true));
    match channel.pop() {
        Some(ChannelValue::Bool(b)) => assert!(b),
        other => panic!("Expected Bool(true), got {:?}", other),
    }

    channel.push(ChannelValue::Bool(false));
    match channel.pop() {
        Some(ChannelValue::Bool(b)) => assert!(!b),
        other => panic!("Expected Bool(false), got {:?}", other),
    }

    // Number round-trip
    channel.push(ChannelValue::Number(3.14));
    match channel.pop() {
        Some(ChannelValue::Number(n)) => assert!((n - 3.14).abs() < f64::EPSILON),
        other => panic!("Expected Number(3.14), got {:?}", other),
    }

    // String round-trip
    channel.push(ChannelValue::String("test".into()));
    match channel.pop() {
        Some(ChannelValue::String(s)) => assert_eq!(s, "test"),
        other => panic!("Expected String(\"test\"), got {:?}", other),
    }
}

#[test]
fn test_channel_supply() {
    let channel = Channel::new();
    assert!(channel.supply(ChannelValue::Number(1.0))); // empty → pushed
    assert!(!channel.supply(ChannelValue::Number(2.0))); // non-empty → rejected
    match channel.pop() {
        Some(ChannelValue::Number(n)) => assert!((n - 1.0).abs() < f64::EPSILON),
        other => panic!("Expected Number(1.0), got {:?}", other),
    }
}

#[test]
fn test_channel_clear() {
    let channel = Channel::new();
    channel.push(ChannelValue::Number(1.0));
    channel.push(ChannelValue::Number(2.0));
    channel.push(ChannelValue::Number(3.0));
    assert_eq!(channel.get_count(), 3);

    channel.clear();
    assert_eq!(channel.get_count(), 0);
    assert!(channel.pop().is_none());
}

#[test]
fn test_channel_peek() {
    let channel = Channel::new();
    assert!(channel.peek().is_none());

    channel.push(ChannelValue::Number(42.0));
    // Peek does not remove the value
    match channel.peek() {
        Some(ChannelValue::Number(n)) => assert!((n - 42.0).abs() < f64::EPSILON),
        other => panic!("Expected Number(42.0), got {:?}", other),
    }
    assert_eq!(channel.get_count(), 1);

    // Pop still removes it
    channel.pop();
    assert_eq!(channel.get_count(), 0);
}

#[test]
fn test_channel_get_count() {
    let channel = Channel::new();
    assert_eq!(channel.get_count(), 0);
    channel.push(ChannelValue::Nil);
    assert_eq!(channel.get_count(), 1);
    channel.push(ChannelValue::Bool(true));
    assert_eq!(channel.get_count(), 2);
    channel.pop();
    assert_eq!(channel.get_count(), 1);
}

// ── Thread tests ─────────────────────────────────────────────────────

#[test]
fn test_thread_runs_code() {
    let channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> = Arc::new(Mutex::new(HashMap::new()));
    let result_ch = Channel::named("result".into());
    channels
        .lock()
        .unwrap()
        .insert("result".into(), result_ch.clone());

    let mut thread = LuaThread::new(
        r#"
            local ch = lurek.thread.getChannel("result")
            ch:push(42)
        "#
        .into(),
        channels,
    );
    thread.start(vec![]).unwrap();
    thread.wait();

    assert!(!thread.is_running());
    assert!(thread.get_error().is_none());

    match result_ch.pop() {
        Some(ChannelValue::Number(n)) => assert!((n - 42.0).abs() < f64::EPSILON),
        other => panic!("Expected Number(42.0), got {:?}", other),
    }
}

#[test]
fn test_thread_channel_communication() {
    let channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> = Arc::new(Mutex::new(HashMap::new()));
    let pipe = Channel::named("pipe".into());
    channels.lock().unwrap().insert("pipe".into(), pipe.clone());

    let mut thread = LuaThread::new(
        r#"
            local ch = lurek.thread.getChannel("pipe")
            local val = ch:demand(5.0)
            ch:push(val + 1)
        "#
        .into(),
        channels,
    );
    thread.start(vec![]).unwrap();

    // Push a value from the main thread for the worker to read
    pipe.push(ChannelValue::Number(10.0));

    thread.wait();

    assert!(
        thread.get_error().is_none(),
        "Thread should not error: {:?}",
        thread.get_error()
    );

    // Thread should have pushed 11
    match pipe.pop() {
        Some(ChannelValue::Number(n)) => assert!((n - 11.0).abs() < f64::EPSILON),
        other => panic!("Expected Number(11.0), got {:?}", other),
    }
}

#[test]
fn test_thread_error_captured() {
    let channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> = Arc::new(Mutex::new(HashMap::new()));
    let mut thread = LuaThread::new("error('test error')".into(), channels);
    thread.start(vec![]).unwrap();
    thread.wait();

    let err = thread.get_error().unwrap();
    assert!(
        err.contains("test error"),
        "Error should contain 'test error', got: {}",
        err
    );
}

#[test]
fn test_thread_is_running() {
    let channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> = Arc::new(Mutex::new(HashMap::new()));
    let blocker = Channel::named("blocker".into());
    channels
        .lock()
        .unwrap()
        .insert("blocker".into(), blocker.clone());

    let mut thread = LuaThread::new(
        r#"
            local ch = lurek.thread.getChannel("blocker")
            ch:demand(5.0)
        "#
        .into(),
        channels,
    );

    assert!(!thread.is_running());
    thread.start(vec![]).unwrap();

    // Give the thread a moment to start
    std::thread::sleep(std::time::Duration::from_millis(50));
    assert!(thread.is_running());

    // Unblock the thread
    blocker.push(ChannelValue::Nil);
    thread.wait();
    assert!(!thread.is_running());
}

#[test]
fn test_thread_cannot_restart_while_running() {
    let channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> = Arc::new(Mutex::new(HashMap::new()));
    let blocker = Channel::named("blocker".into());
    channels
        .lock()
        .unwrap()
        .insert("blocker".into(), blocker.clone());

    let mut thread = LuaThread::new(
        r#"
            local ch = lurek.thread.getChannel("blocker")
            ch:demand(5.0)
        "#
        .into(),
        channels,
    );

    thread.start(vec![]).unwrap();
    std::thread::sleep(std::time::Duration::from_millis(50));

    // Starting again while running should fail
    let result = thread.start(vec![]);
    assert!(result.is_err());

    blocker.push(ChannelValue::Nil);
    thread.wait();
}

#[test]
fn test_thread_string_channel_value() {
    let channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> = Arc::new(Mutex::new(HashMap::new()));
    let ch = Channel::named("strings".into());
    channels
        .lock()
        .unwrap()
        .insert("strings".into(), ch.clone());

    let mut thread = LuaThread::new(
        r#"
            local ch = lurek.thread.getChannel("strings")
            ch:push("hello from thread")
        "#
        .into(),
        channels,
    );
    thread.start(vec![]).unwrap();
    thread.wait();

    assert!(thread.get_error().is_none());
    match ch.pop() {
        Some(ChannelValue::String(s)) => assert_eq!(s, "hello from thread"),
        other => panic!("Expected String, got {:?}", other),
    }
}

#[test]
fn test_thread_with_args() {
    let channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> = Arc::new(Mutex::new(HashMap::new()));
    let ch = Channel::named("args_result".into());
    channels
        .lock()
        .unwrap()
        .insert("args_result".into(), ch.clone());

    let mut thread = LuaThread::new(
        r#"
            local ch = lurek.thread.getChannel("args_result")
            -- Args are in the global 'arg' table
            ch:push(arg[1])
            ch:push(arg[2])
        "#
        .into(),
        channels,
    );
    thread
        .start(vec![
            ChannelValue::Number(100.0),
            ChannelValue::String("test_arg".into()),
        ])
        .unwrap();
    thread.wait();

    assert!(
        thread.get_error().is_none(),
        "Thread errored: {:?}",
        thread.get_error()
    );

    match ch.pop() {
        Some(ChannelValue::Number(n)) => assert!((n - 100.0).abs() < f64::EPSILON),
        other => panic!("Expected Number(100.0), got {:?}", other),
    }
    match ch.pop() {
        Some(ChannelValue::String(s)) => assert_eq!(s, "test_arg"),
        other => panic!("Expected String(\"test_arg\"), got {:?}", other),
    }
}

#[test]
fn test_channel_demand_with_producer_thread() {
    let channel = Channel::new();
    let ch = channel.clone();

    // Spawn a thread that pushes after a delay
    let producer = std::thread::spawn(move || {
        std::thread::sleep(std::time::Duration::from_millis(50));
        ch.push(ChannelValue::String("delayed".into()));
    });

    // demand() should block until the value arrives
    let result = channel.demand(Some(5.0));
    producer.join().unwrap();

    match result {
        Some(ChannelValue::String(s)) => assert_eq!(s, "delayed"),
        other => panic!("Expected String(\"delayed\"), got {:?}", other),
    }
}
