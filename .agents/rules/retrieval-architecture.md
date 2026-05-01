---
description: "Load when designing or maintaining retrieval corpus shape, chunking, freshness, source ranking, or RAG evaluation for agent support. Skip for generic .github authoring, prompt wording, or engine code."
alwaysApply: false
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
- Current authoritative knowledge sources are docs/specs/, docs/architecture/, .agents/, tools/README.md, and extensions/vscode/src/mcp/.
- Chunk by artifact type and ownership boundary first because one module spec or one agent contract usually carries meaning that fixed-size slicing destroys.
- Distinguish canonical sources from generated artifacts, logs, reports, and saved outputs in freshness rules.
- Retrieval metadata should carry path, source type, topic or module, freshness source, and a human-readable title.
- Freshness should follow the real source-of-truth file or generator boundary.
- Evaluate recall on exact contract and workflow questions, stale-source failure cases, noisy-context cases, and ambiguous ownership queries.
- Avoid indexing multiple generated variants of the same fact at equal priority.

## References
- docs/specs/
- docs/architecture/
- .agents/
- tools/README.md
- extensions/vscode/src/mcp/
- logs/data/
