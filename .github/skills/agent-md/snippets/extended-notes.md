- List module functions and UserData methods as bullets
- Must stay aligned with `src/lua_api/<module>_api.rs`

### `## References`

- One bullet per module dependency or closely related module
- Explain relationship and separation of duties
- Source-derived list can be regenerated, but the notes may need manual refinement

### `## Notes`

Capture anything important that does not fit above:
- External crate constraints
- Hardware or OS-specific behavior
- Known omissions or sharp edges
- Migration warnings
- Practices future editors should not infer from the generated sections alone

### Sync Contract
Keep `docs/specs/<module>.md` synchronized with:

| What changes | What to update |
|--------------|----------------|
| New `.rs` file added | `## Files` |
| Public type added/removed | `## Types` |
| Public function added/removed | `## Functions` |
| Lua binding added/renamed/removed | `## Lua API Reference` |
| Dependency added/removed | `## References` and, if behavior changes, `## Summary` or `## Notes` |
| Scope boundary changed | `## Summary` and `## Notes` |
| Tests moved or renamed | `## General Info` |

### Scaffolding vs Manual Prose
`tools/docs/gen_module_specs.py` refreshes the source-derived sections and preserves manual Summary and Notes text when it already exists.

The Summary should not be treated as boilerplate. It must be reviewed and expanded module by module using the actual source code. The generated structure is only the starting point.

### Anti-Patterns
- Reintroducing `src/<module>/AGENT.md` as a second source of truth
- Leaving Summary as one generic sentence after regeneration
- Listing files, types, or functions that no longer exist
- Copying Lua API descriptions without checking `src/lua_api/<module>_api.rs`
- Treating the generated sections as a substitute for Notes when important caveats exist
- Leaving `TODO:` placeholders in committed module references
