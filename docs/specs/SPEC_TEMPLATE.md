# `<module>`

<!--
  TEMPLATE — merged module reference format.
  Copy this file to docs/specs/<module>.md and fill in every section.
  Summary and Notes are manual prose.
  Files, Types, Functions, Lua API Reference, and References are intended to be
  scaffolded by tools/docs/gen_module_specs.py and then revised manually.
-->

## General Info

- Module group: `<Foundations | Core Runtime | Platform Services | Feature Systems | Edge/Integration>`
- Source path: `src/<module>/`
- Lua API path(s): `src/lua_api/<module>_api.rs` or `None direct`
- Primary Lua namespace: `lurek.<namespace>` or `None direct`
- Rust test path(s): `tests/rust/unit/<module>_tests.rs`
- Lua test path(s): `tests/lua/unit/test_<module>.lua`

## Summary

- Several sentences describing the module's purpose, design, and public interface.
- Describe the module's scope boundary and how it interacts with other modules.

## Files

- `mod.rs`: Module root and re-export surface.
- `type_a.rs`: Describe the file's purpose.
- `type_b.rs`: Describe the file's purpose.

## Types

- `TypeA` (`struct`, `type_a.rs`): Describe what the type is for.
- `TypeB` (`enum`, `type_b.rs`): Describe what the type is for.

## Functions

- `TypeA::new` (`type_a.rs`): Describe what the function or method does.
- `do_work` (`type_b.rs`): Describe what the function does.

## Lua API Reference

- Binding path(s): `src/lua_api/<module>_api.rs`
- Namespace: `lurek.<namespace>`

### Module Functions

- `lurek.<namespace>.example`: Describe what the binding exposes.

### `TypeA` Methods

- `TypeA:method`: Describe what the Lua-visible method does.

## References

- `math`: Explain why this module depends on or interacts with `src/math/`.
- `runtime`: Explain the separation of duties with `src/runtime/`.

## Notes

- Record any important facts that do not fit the sections above.
- Capture constraints, gotchas, migration warnings, or platform caveats here.
