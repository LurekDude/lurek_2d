# Lurek2D — TOGAF Research Brief

> Evidence-first background note for future `Architect` and `CAG Architect` work.
> This file does **not** claim that Lurek2D follows TOGAF today. It documents what TOGAF is, what parts are likely relevant for later comparison, and where source confidence is limited by public-access constraints.

---

## Purpose

This brief exists so later architecture work can compare Lurek2D against TOGAF from a shared fact base instead of from memory or certification folklore.

Use this file when you need to answer questions like:

- What does TOGAF actually standardize?
- Which TOGAF concepts are process-oriented versus artifact-oriented?
- Which parts could be compared to Lurek2D architecture docs, CAG docs, and governance docs?
- What should be treated cautiously because the public sources are promotional, incomplete, or version-mixed?

This file is intentionally a **research note**, not a conformance document and not an adoption plan.

---

## Executive Summary

TOGAF is an enterprise architecture standard published by The Open Group. Official public pages describe it as both a methodology and a framework, with the `Architecture Development Method` (ADM) as its central lifecycle method and with the 10th Edition split into `Fundamental Content` plus `Series Guides` for context-specific adaptation.

For Lurek2D, the immediate value of TOGAF is not a direct process transplant. The value is as a comparison lens for:

- architecture principles and constraints
- architecture artifacts and repository structure
- governance and review checkpoints
- vocabulary for capabilities, stakeholders, and change planning

The main caution is that TOGAF is designed for enterprise architecture at organizational scale. Official sources emphasize adaptability and broad applicability, while secondary sources and criticism warn that teams often have to tailor it heavily and that the framework can become too abstract when applied mechanically.

Confidence level for this brief is **medium**. Public official sources were enough to confirm the high-level shape of TOGAF 10, but several deep pages in the TOGAF Library were access-controlled from this environment, so some lower-level concept descriptions rely on a neutral secondary source that summarizes earlier public TOGAF material.

---

## Source Status

### Official public sources available from this environment

- The Open Group TOGAF landing page: `https://www.opengroup.org/togaf`
- The Open Group benefits page for the 10th Edition: `https://www.opengroup.org/togaf/benefits`
- The Open Group 10th Edition announcement: `https://www.opengroup.org/open-group-announces-launch-togaf-standard-10th-edition`

### Sources that were partially or fully access-controlled here

- `https://pubs.opengroup.org/...`
- `https://publications.opengroup.org/...`
- `https://www.opengroup.org/togaf/10thedition`

### Secondary source used to fill public-access gaps

- Wikipedia summary page: `https://en.wikipedia.org/wiki/The_Open_Group_Architecture_Framework`

The secondary source was used only for concepts that the public official pages referenced but did not expose in detail from this environment, especially `ADM`, the four architecture domains, and `Enterprise Continuum` terminology.

---

## What TOGAF Is

From the public The Open Group pages, TOGAF should be understood as a **standardized enterprise architecture method and framework** rather than as a single fixed template. The official wording repeatedly stresses three ideas:

- TOGAF is a standard of The Open Group.
- It is meant to improve business efficiency and organizational alignment.
- It is configured in practice rather than copied as a rigid one-size-fits-all playbook.

The public TOGAF 10 material also makes one structural point very clearly: the standard is split into:

- `TOGAF Fundamental Content`: core concepts and core practices
- `TOGAF Series Guides`: guidance for configuring those concepts to different contexts and use-cases

That split matters for later Lurek2D work because it suggests a comparison strategy: separate universal concepts from project-specific adaptations instead of trying to map every TOGAF document part 1:1 onto the repo.

---

## Core TOGAF Concepts Relevant To Later Comparison

### 1. ADM: Architecture Development Method

The `Architecture Development Method` is the core lifecycle method of TOGAF. Secondary public summaries describe it as the central process for developing and managing enterprise architecture over time, and emphasize that it is both **iterative** and **tailorable** to the organization.

What matters for future Lurek2D comparison is not the exact phase diagram first. What matters is the ADM shape:

- it is lifecycle-oriented
- it loops through requirements repeatedly
- it assumes architecture evolves through governed change, not one-shot design

For Lurek2D, this suggests a later comparison around questions like:

- where the repo defines architecture phases or gates
- where requirements and constraints re-enter the process
- where change approval and architecture review happen

This is a comparison cue only, not a recommendation to adopt ADM wholesale.

### 2. Four architecture domains

The secondary public summary describes TOGAF as commonly modeled at four levels:

- `Business`
- `Data`
- `Application`
- `Technology`

For an engine project like Lurek2D, this is not a natural fit out of the box, because the repo is not an internal IT estate. Still, the model is useful as a decomposition lens.

Possible comparison questions for later work:

- What is the Lurek2D equivalent of `Business Architecture`? Product goals, contributor workflow, stakeholder personas, adoption constraints?
- What is the equivalent of `Data Architecture`? Serialized formats, runtime data contracts, generated docs data, config schemas?
- What is the equivalent of `Application Architecture`? Runtime services, engine subsystems, extension surface, CAG layer, VS Code extension?
- What is the equivalent of `Technology Architecture`? Rust, LuaJIT, wgpu, winit, toolchain, packaging, validation stack?

The important takeaway is that TOGAF distinguishes layers of concern. Later mapping work should decide whether these four domains need direct mapping, partial mapping, or a consciously different equivalent for a product/repo context.

### 3. Enterprise Continuum and reusable assets

The public summaries describe the `Enterprise Continuum` as a way of classifying architecture and solution assets from generic foundation material to organization-specific implementations. It also distinguishes an `Architecture Continuum` from a `Solutions Continuum`.

For Lurek2D, this concept may become useful when comparing:

- reusable architecture rules versus repo-specific implementation rules
- abstract architecture principles versus concrete code-generation and validation tooling
- general contributor patterns versus product-specific conventions

If later architects use TOGAF as a lens, this concept likely maps better to the repo's layered documentation and template system than to runtime code alone.

### 4. Architecture repository and deliverables

The official benefits page states that TOGAF gives tool vendors a reference model for architecture views, deliverables, an enterprise architecture repository, ADM, and a governance framework. That is useful because it points to TOGAF as not only a method, but also a structure for storing and reviewing architecture artifacts.

The most obvious comparison area in this repo is the existing split across:

- `docs/architecture/`
- `docs/specs/`
- `.github/` CAG files
- `tools/validate/`
- `work/` session artifacts

Future architecture work can ask whether these already behave like a lightweight architecture repository, even if the repo never adopts TOGAF terminology directly.

### 5. Governance and controlled adaptation

Public TOGAF 10 pages stress both best practice and configuration. The standard is described as modular, scalable, and applicable across many types of architecture work, including agile and digital transformation settings.

That combination implies a governance stance:

- some concepts are stable
- some guidance is selected per context
- architecture work is expected to be governed, not improvised

This is relevant to Lurek2D because the repo already contains strong architectural constraints, validation scripts, artifact ownership rules, and cross-artifact sync rules. Later work can compare those governance mechanisms to TOGAF-style governance without pretending they are the same thing.

---

## What TOGAF 10 Changes In Practice

The clearest public signal from the official 10th Edition material is the separation between stable concepts and configurable guidance.

The Open Group public pages frame the 10th Edition as:

- easier to adopt than earlier editions
- broader in guidance and how-to material
- explicitly usable across different architecture styles and transformation cases
- built around `Fundamental Content` plus `Series Guides`

For later comparison work, that means the right question is probably not:

- "Does Lurek2D match TOGAF?"

The better questions are likely:

- Which TOGAF fundamentals resemble what Lurek2D already documents as binding constraints?
- Which TOGAF guide-style material would correspond to repo-specific practices, templates, and agent workflows?
- Where would TOGAF be too heavy for a single-product engine repo?

---

## Contradiction Note

The source picture is not fully uniform.

### Official framing

Official The Open Group pages present TOGAF as:

- proven
- broadly adopted
- scalable
- configurable
- suitable across many enterprise use-cases

### Secondary critical signal

The neutral secondary summary also includes a long criticism section based on published commentary and studies. The recurring criticism is that TOGAF can be:

- too generic
- difficult to follow literally
- adapted so heavily in practice that real usage diverges from the published method

This contradiction matters. For Lurek2D, later TOGAF comparison work should explicitly avoid a checkbox-style compliance exercise. If TOGAF is used here at all, it should be used as a vocabulary and analysis lens, not as a ceremonial process overlay.

---

## Likely Comparison Surfaces Inside This Repo

This section is intentionally narrow. It identifies only the most plausible future comparison surfaces and does not yet perform the comparison.

| TOGAF concern | Most likely Lurek2D comparison surface |
| ------------- | -------------------------------------- |
| Principles / stable constraints | `docs/architecture/philosophy.md` |
| Architecture structure and module boundaries | `docs/architecture/engine-architecture.md` |
| Governance, validator rules, and controlled authoring | `docs/architecture/cag-system.md`, `.github/copilot-instructions.md`, `tools/validate/` |
| Architecture repository / artifacts | `docs/`, `.github/`, `work/`, generated docs, validation reports |
| Delivery and test governance | `docs/architecture/test-framework.md`, task definitions, quality scripts |
| Practice-specific guidance | skills, prompts, templates, handbook workflow |

These surfaces are likely where future `Architect` and `CAG Architect` work should begin.

---

## Questions For Architect / CAG Architect

These are the next high-value questions after this brief.

1. Which TOGAF concepts should be treated as analysis lenses only, and which are worth encoding in repo docs or skills?
2. Should Lurek2D compare itself to TOGAF at the level of `principles`, `artifacts`, `governance`, `process`, or all four separately?
3. What is the correct project-specific substitute for TOGAF's `Business / Data / Application / Technology` split in an engine-plus-tooling repository?
4. Does the current `docs/ + .github/ + tools/validate/ + work/` structure already function as a lightweight architecture repository?
5. Which parts of TOGAF are too enterprise-heavy to be useful for a product-centric open-source engine workflow?
6. Do future skills need TOGAF vocabulary for review and planning, or only selected patterns such as principles, deliverables, and governance checkpoints?

---

## Confidence And Gaps

### High confidence

- TOGAF is an enterprise architecture standard owned by The Open Group.
- ADM is central to TOGAF.
- TOGAF 10 separates `Fundamental Content` from `Series Guides`.
- Official messaging emphasizes configuration, best practice, and broad applicability.

### Medium confidence

- The practical meaning of some lower-level TOGAF concepts in this brief is reconstructed from public summaries because direct TOGAF Library pages were access-controlled from this environment.
- The value of `Enterprise Continuum` and `repository` concepts for Lurek2D is plausible but still untested against the repo in a formal mapping exercise.

### Open gaps

- A future pass with authenticated access to the TOGAF Library should confirm exact 10th Edition wording for ADM-related and repository-related definitions.
- No attempt was made here to compare TOGAF with other architecture frameworks such as Zachman, ArchiMate, or ISO/IEC/IEEE 42010.
- No attempt was made here to score Lurek2D against TOGAF; that belongs in a later document.

---

## Sources

- The Open Group, TOGAF overview: `https://www.opengroup.org/togaf`
- The Open Group, Benefits of the TOGAF Standard, 10th Edition: `https://www.opengroup.org/togaf/benefits`
- The Open Group, launch announcement for the 10th Edition: `https://www.opengroup.org/open-group-announces-launch-togaf-standard-10th-edition`
- Wikipedia, TOGAF summary page used only for public-access gaps: `https://en.wikipedia.org/wiki/The_Open_Group_Architecture_Framework`

---

## Follow-on Documents

This research brief is now complemented by two mapping documents:

- [togaf-mapping.md](togaf-mapping.md) — current-state crosswalk from TOGAF concepts onto real Lurek2D artifacts.
- [togaf-gap-analysis.md](togaf-gap-analysis.md) — fit assessment, weak spots, and smallest safe next steps.

Keep this file as the source-limited terminology and source-status brief. Put repo-specific interpretation and structural conclusions in the follow-on documents above.