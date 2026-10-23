---
name: spectra-design-review
description: Present the agent's understanding of a design so the person can correct it, then settle each gap with a grill. Use when the user asks to review understanding, walk a design or proposal, confirm the overall picture, or continue or redo part of a design review.
---

Needs: the sources of one design (an OpenSpec change under `openspec/changes/`, the specs under `openspec/specs/`, ADRs and the current code), and a chat that renders Mermaid diagrams.

Identity: `spectra-design-review`. Invoke it as `/spectra-design-review` or `/spectra-design-review <change>`.

This skill shows the person what you understand of a design, so that the person can correct it. Read the sources. Do not review from a generated document or from an earlier summary. A review that you wrote before is output, not input. Rebuild the whole review from the sources each time.

## 1. Choose the mode first

Ask how to give the review, before you read deep or write a section. Skip the question when the request already names a mode.

- __One go__: the whole outline in one response.
- __Section by section__: one section for each turn. Stop after each section and name the next one. Continue only when the person asks to move on, for example with "next". When the person asks for a section again, replace that section and do not advance.

## 2. Find the sources

- The change: `openspec/changes/<change>/proposal.md`, `specs/`, `design.md`. Ask which change when the argument names none and more than one is active.
- The durable specs: `openspec/specs/`.
- ADRs and the domain glossary: `docs/adr/`, `docs/glossary.md`, and `docs/glossary-map.md` when the repo has more than one context. Read the files that `AGENTS.md` names in its read order.
- The current code and schema of the path that the design changes.

A repo that lacks a source says so in the review. Do not fill the gap with a guess.

## 3. The outline

Use an outline that the person gives. Otherwise use this one.

1. Overview
2. Problem Statement
3. Solution Overview
4. Solution Details
   1. System design
      1. High-level architecture diagram
      2. Key decisions (ADRs)
      3. Containers, each marked New, Changed or Existing: database, API, and each other container whose behavior changes
   2. Domain design
      1. Context map diagram, when a domain model exists
      2. Domain model diagram, when a domain model exists
      3. Entity changes
   3. Application design
      1. API
      2. Events

## 4. The Problem Statement is the current state

Write what happens today, why that is a problem, and the constraints that matter now. Do not use a change column or the words Stays, Added, Changed or Removed in this section. Those words need the solution, which comes later. Do not add a row only to say that absent behavior stays absent. Put every before-and-after comparison in Solution Overview or Solution Details. When both paths matter, split the current path and the new path there. For example:

- Reads come from the cache: Stays
- Writes also go to the queue: Added

## 5. Status words

Ground every name in the current contract. Use these words and no others. Do not use the word "proposed".

- __Stays__: it is in the contract today, and this change does not alter it.
- __Added__: it is decided, even when it is not in code yet. Say that the current contract lacks it.
- __Changed__: the path does this today, and this change alters it.
- __Removed__: it is in the contract today, and this change drops it.
- __Open__: the source does not decide it. It is a review gap.
- __Inferred__: an assumption that no source states. Confirm it or drop it.

A status applies to one behavior. Split a row that mixes "the type exists" with "this change uses it". Judge the path that changes, not whether a symbol exists somewhere in the code. A path that does not do something today and that this change requires it to do is Added, even when a type, a table or a policy already exists. A new capability in the proposal is never Stays.

A label such as "Changed" is not enough. Name the field, type, column, rule or behavior that changes. For a new entity, list every attribute. For an existing one, say what it is today and what changes.

Show each structural change (database, API, events, entities) in the same shape: a nested list with one item for each name.

- `<name>`: Stays
- `<name>`: Added. The rule that it carries. Not in code yet.
- `<name>`: Removed
- `<name>`: Not added. Where it is visible instead.
- `<name>`: Open. The decision that is still required.

## 6. Diagrams

Include a real diagram, not prose and not ASCII art, in these places. Use Mermaid in a fenced `mermaid` block.

- __4.1.1 High-level architecture__: always. Show the runtime containers or modules, the external actors and systems, and the direction of the main calls or data flow. Mark each node New, Changed or Existing, and put the material change on the node.
- __4.2.1 Context map__: when the design has a domain model. Show the bounded contexts and the directed relations between them. Label each relation with what crosses it. Do not put entities in the map.
- __4.2.2 Domain model__: when the design has a domain model. Split it by bounded context. Show aggregates, entities, value objects, important attributes and relations. A relation across contexts is an id reference, not a shared entity. Use one diagram for each context when one diagram would be crowded.

Use short labels and directed edges. Add a legend when colors or line styles carry meaning. Split a crowded diagram instead of shrinking it. Mark a name that the current code lacks as Added.

## 7. The consistency pass

Before you finish, check every material claim in both directions. A material claim is a behavior, a contract field, a persistence fact, a lifecycle rule, an ownership boundary or a status word. Check these sources: the proposal (scope, outcomes, exclusions, capabilities), the specs (required behavior, scenarios, failure handling), the ADRs (settled decisions and rejected options), the design (order, ownership, persistence, integrations), the current code and schema, and the glossary.

- Source to review: every material decision or requirement appears in the review, and is correct.
- Review to source: every claim has evidence and does not contradict another source.

When two sources disagree, use this precedence and flag the lower one as stale. Do not pick a wording in silence.

1. A confirmed decision or ADR
2. The specs
3. The design
4. The proposal
5. Inference

Map each new or modified capability, each ADR decision and each spec requirement that changes behavior to the review rows that describe it. Confirm the status of each row.

## 8. Settle the gaps

After you show the whole review, look for gaps: a contradiction between sources or code, a behavior that the sources assume without stating it, a fuzzy domain term, a missing owner or boundary, an unspecified failure, and an open trade-off. A visible warning does not settle a gap. Settle it, or establish that the source leaves it open on purpose.

When no gap remains, say so in one sentence and finish.

When a gap remains, run `spectra-grill` in this conversation. Read `.agents/skills/spectra/spectra-grill/SKILL.md` and follow it. When you cannot read it, stop and say so. Do not ask the person to run it.

1. Ask the open frontier questions yourself, numbered, each with your recommended answer. Then wait.
2. Finding facts is your job. Read the sources and the code before you ask. Ask the person only for decisions. Base each recommendation on the facts, on invariants that hold, and on recorded decisions.
3. When an answer settles a term or a boundary, update `docs/glossary.md` in that turn (the context glossary that `docs/glossary-map.md` names for a multi-context repo). Record an ADR only when the decision is hard to reverse, is surprising without its context, and rests on a real trade-off.
4. After the person confirms the shared understanding, update the proposal, specs or design of the reviewed change where a resolved decision made them stale. Then rebuild the affected part of the review.
5. Continue in rounds until the frontier is empty and the person confirms.

In one-go mode, add the first round of questions after the review. In section-by-section mode, start the gap step only after the last section.
