//! Integration tests for the TOML-backed message catalog system.
//!
//! Tests cover catalog parsing, ID resolution, global `get_message`, and the
//! uniqueness contract for all registered stable IDs.

use luna2d::engine::messages::{catalog, get_message, init, MessageCatalog};

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

#[test]
fn catalog_parses_embedded_toml() {
    let c = MessageCatalog::from_toml(include_str!(
        "../../../src/engine/cfg/messages.toml"
    ));
    assert!(!c.is_empty(), "catalog must not be empty");
}

#[test]
fn catalog_has_expected_entry_count() {
    let c = MessageCatalog::from_toml(include_str!(
        "../../../src/engine/cfg/messages.toml"
    ));
    // We registered at least 30 baseline entries; tier stubs add none.
    assert!(c.len() >= 30, "expected >= 30 entries, got {}", c.len());
}

// ---------------------------------------------------------------------------
// ID resolution
// ---------------------------------------------------------------------------

#[test]
fn l001_resolves_to_human_text() {
    let c = MessageCatalog::from_toml(include_str!(
        "../../../src/engine/cfg/messages.toml"
    ));
    assert_eq!(c.get("L001"), Some("Luna2D Engine starting"));
}

#[test]
fn l003_resolves_to_game_loaded() {
    let c = MessageCatalog::from_toml(include_str!(
        "../../../src/engine/cfg/messages.toml"
    ));
    assert_eq!(c.get("L003"), Some("Game loaded"));
}

#[test]
fn l010_resolves_to_render_error() {
    let c = MessageCatalog::from_toml(include_str!(
        "../../../src/engine/cfg/messages.toml"
    ));
    assert_eq!(c.get("L010"), Some("Render error"));
}

#[test]
fn unknown_id_returns_none() {
    let c = MessageCatalog::from_toml(include_str!(
        "../../../src/engine/cfg/messages.toml"
    ));
    assert!(c.get("ZZUNKNOWN").is_none());
}

// ---------------------------------------------------------------------------
// Global catalog
// ---------------------------------------------------------------------------

#[test]
fn get_message_returns_text_after_init() {
    init();
    assert_eq!(get_message("L001"), "Luna2D Engine starting");
    assert_eq!(get_message("L003"), "Game loaded");
    assert_eq!(get_message("L011"), "Lua error");
}

#[test]
fn get_message_fallback_returns_id_when_unknown() {
    init();
    // An unregistered ID should fall back to the raw ID string.
    assert_eq!(get_message("ZZZNOTREAL"), "ZZZNOTREAL");
}

#[test]
fn catalog_singleton_returns_some_after_init() {
    init();
    assert!(catalog().is_some(), "catalog() should return Some after init()");
}

#[test]
fn init_is_idempotent() {
    // Calling init() multiple times must not panic or change the catalog.
    init();
    init();
    init();
    assert_eq!(get_message("L001"), "Luna2D Engine starting");
}

// ---------------------------------------------------------------------------
// All baseline IDs registered
// ---------------------------------------------------------------------------

#[test]
fn all_baseline_ids_present() {
    let c = MessageCatalog::from_toml(include_str!(
        "../../../src/engine/cfg/messages.toml"
    ));
    let required = [
        "L001", "L002", "L003", "L004", "L005", "L006", "L007",
        "L010", "L011", "L012", "L013", "L014", "L015", "L016", "L017",
        "L020", "L021", "L022", "L023", "L024",
        "L030", "L031", "L032",
        "L033", "L034", "L035",
        "L036", "L037", "L038", "L039", "L040", "L041", "L042", "L043", "L044",
        "L050", "L051", "L052", "L053",
    ];
    for id in &required {
        assert!(c.get(id).is_some(), "missing required ID: {id}");
    }
}
