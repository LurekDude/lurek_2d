---
name: retrieval-architecture
description: "Load this skill when designing or maintaining retrieval corpus shape, chunking, freshness, source ranking, or RAG evaluation for agent support. Skip it for generic .github authoring, prompt wording, or engine code."
---
# retrieval-architecture

## Mission
- Own retrieval corpus design, freshness rules, and evaluation for agent-facing knowledge.

## When To Load
- Define a retrieval corpus.
- Add or change chunking rules.
- Design source ranking or provenance.
- Evaluate RAG quality or freshness.

## When To Skip
- Generic CAG writing.
- Engine code work.
- Non-retrieval docs updates.

## Domain Knowledge
- Current authoritative knowledge sources are docs/specs/, docs/architecture/, .github/, tools/README.md, and extension MCP-facing code under extensions/vscode/src/mcp/.
- Chunk by artifact type and ownership boundary first; fixed-size slicing alone loses contract meaning.
- Distinguish canonical sources from generated artifacts, logs, and reports in freshness rules.
- Retrieval metadata should carry path, source type, topic or module, freshness source, and human-readable title.
- Evaluate recall on exact contract and workflow questions, plus stale-source and noisy-context failure cases.
- Generic prompt or agent wording stays with CAG-Architect; this skill owns retrieval-specific support layers.
- Retrieval support here should privilege canonical contracts like docs/specs, CAG files, tools/README.md, and extension MCP integration before logs or generated snapshots.
- Chunking should preserve ownership boundaries such as one module spec, one agent contract, or one tool entry whenever possible.
- The skill owns retrieval corpus quality and freshness, not general CAG prose or extension UI behavior.
## Companion File Index
- None.

## References
- docs/specs/
- docs/architecture/
- .github/
- tools/README.md
- extensions/vscode/src/mcp/
- logs/data/
