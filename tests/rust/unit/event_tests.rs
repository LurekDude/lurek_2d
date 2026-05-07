mod event_queue_tests {
    use lurek2d::event::{event_to_lua_multi, Event, EventArg, EventPriority, EventQueue};
    use mlua::Lua;

    #[test]
    fn high_priority_lane_drains_before_normal_lane() {
        let mut queue = EventQueue::new();
        queue.push_event("normal", vec![]);
        queue.push_event_with_priority("high", vec![], EventPriority::High);

        let first = queue.poll().expect("first event");
        let second = queue.poll().expect("second event");

        assert_eq!(first.name, "high");
        assert_eq!(second.name, "normal");
    }

    #[test]
    fn wait_zero_timeout_returns_none_when_empty() {
        let mut queue = EventQueue::new();
        let got = queue.wait(Some(0));
        assert!(got.is_none());
    }

    #[test]
    fn event_table_payload_roundtrips_to_lua_multivalue() {
        let lua = Lua::new();
        let event = Event {
            name: "payload".to_string(),
            args: vec![EventArg::Table(vec![(
                lurek2d::event::EventTableKey::Str("hp".to_string()),
                EventArg::Num(12.0),
            )])],
        };

        let values = event_to_lua_multi(&lua, &event).expect("event to lua");
        assert_eq!(values.len(), 2);

        let payload_tbl = match &values[1] {
            mlua::Value::Table(tbl) => tbl,
            other => panic!("expected table payload, got {other:?}"),
        };

        let hp: f64 = payload_tbl.get("hp").expect("hp key");
        assert!((hp - 12.0).abs() < f64::EPSILON);
    }
}

mod signal_glob_tests {
    use lurek2d::event::Signal;

    #[test]
    fn wildcard_supports_multi_star_sequences() {
        let mut signal = Signal::new();
        let handle = signal.subscribe_wildcard("enemy**.hit");
        let handles = signal.get_wildcard_handles("enemy_boss.hit");
        assert_eq!(handles, vec![handle]);
    }

    #[test]
    fn wildcard_supports_adjacent_stars() {
        let mut signal = Signal::new();
        let handle = signal.subscribe_wildcard("damage**");
        let handles = signal.get_wildcard_handles("damage.fire");
        assert_eq!(handles, vec![handle]);
    }

    #[test]
    fn wildcard_empty_pattern_matches_only_empty_name() {
        let mut signal = Signal::new();
        let handle = signal.subscribe_wildcard("");
        let empty_match = signal.get_wildcard_handles("");
        let non_empty_match = signal.get_wildcard_handles("x");

        assert_eq!(empty_match, vec![handle]);
        assert!(non_empty_match.is_empty());
    }
}
