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
- Current authoritative knowledge sources are docs/specs/, docs/architecture/, .github/, tools/README.md, and extension MCP-facing code under extensions/vscode/src/mcp/; ranking should privilege those over incidental artifacts.
- Chunk by artifact type and ownership boundary first because one module spec, one agent contract, or one tool entry usually carries meaning that fixed-size slicing destroys.
- Distinguish canonical sources from generated artifacts, logs, reports, and saved outputs in freshness rules so the retriever does not over-trust stale or derivative text.
- Retrieval metadata should carry path, source type, topic or module, freshness source, and a human-readable title so later evaluation can reason about why a chunk ranked.
- Freshness should follow the real source-of-truth file or generator boundary; generated output should not outrank the source file that will actually be edited.
- Evaluate recall on exact contract and workflow questions, stale-source failure cases, noisy-context cases, and ambiguous ownership queries because those are the practical failure modes in this repo.
- Retrieval support here should privilege canonical contracts like docs/specs, CAG files, tools/README.md, and extension MCP integration before logs or generated snapshots.
- Chunking should preserve ownership boundaries such as one module spec, one agent contract, one skill, or one tool section whenever possible.
- Avoid indexing multiple generated variants of the same fact at equal priority; duplicates dilute ranking and make stale answers harder to spot.
- Generic prompt or agent wording stays with CAG authoring layers; this skill owns retrieval-specific source selection and freshness.
## Companion File Index
- None.

## References
- docs/specs/
- docs/architecture/
- .github/
- tools/README.md
- extensions/vscode/src/mcp/
- logs/data/
