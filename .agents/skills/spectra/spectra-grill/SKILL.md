---
name: spectra-grill
description: Grill a plan until domain terms are confirmed, and write each confirmed term to the glossary. Use when the user wants to stress-test a plan or settle domain language.
source: authored for Spectra pack; glossary paths align with spectra.config.ts OpenSpec rules
---

Needs: a plan or proposal topic that the person gives you, and write access to `docs/glossary.md`.

Interview the user relentlessly until you reach a shared understanding. Map this as a __design tree__: every decision branches into the decisions that hang off it. A fuzzy, overloaded, or conflicting domain term is one of those decisions.

Work the tree in __rounds__. The __frontier__ is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ __Q1__ - __<question title>__: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ __Q2__ - __<question title>__: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

## Glossary

Follow [glossary-format.md](./glossary-format.md) for entry shape and single- vs multi-context layout.

Before the first question, read the glossary files that apply:

- If `docs/glossary-map.md` exists, read it, infer which context the current topic belongs to (ask if unclear), and read that context's `glossary.md` in full.
- If only `docs/glossary.md` exists, read the whole domain glossary.
- If neither exists yet, skip until the first confirmed term needs a file.

Most Spectra repos start with a single context:

```
docs/
├── glossary.md
└── adr/
```

When the work covers a second context, write `docs/glossary-map.md`. The map points at each context's `glossary.md`. Create either file when the first confirmed term needs it. Write `docs/glossary-map.md` only when a second context exists.

When the user uses a term that conflicts with the active context glossary, ask which meaning they intend. When the user uses a vague or overloaded term, recommend one canonical term and ask them to confirm it. Stress-test a domain relationship with a concrete scenario when the boundary between two terms is still open. When the user states how something works, check whether the code agrees, and ask which one is right when they differ.

When the person confirms a term, update the active context's `glossary.md` in that turn (`docs/glossary.md` for single-context repos; the path from `docs/glossary-map.md` for multi-context). Do not write a term before that confirmation. `glossary.md` is a glossary and nothing else. It holds domain language. It does not hold implementation details.

The session is done when the frontier is empty and the user confirms shared understanding. Do not draft the proposal until that confirmation. Do not write `design.md` when the interview finishes.
