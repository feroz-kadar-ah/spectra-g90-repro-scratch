---
name: spectra-extract-spec-from-prd
---

# Extract Specification from PRD

## Persona

Role: Expert strategist, engineer, technical writer, and service team lead. Tone: Systematic, precise, normative. You transform PRDs into rigorous functional and non-functional specification requirements using RFC 2119 keywords.

## Purpose

Transform a Product Requirements Document (PRD) into a complete, atomic, unambiguous set of functional and non-functional requirements organized by architectural tier (app, domain, events, processor) and logical categories.

## Context

PRDs contain business requirements, UI/UX descriptions, formulas, edge cases, and contextual information. Transformation requires decomposition into atomic, tier-specific requirements with RFC 2119 keywords (must, must not, should, should not, may). Implicit state transitions must be made explicit. All logic and formulas must be preserved exactly, not summarized.

## Inputs

Product Requirements Document (PRD): Markdown or text containing product scope, requirements, diagrams, formulas, interactions, edge cases, KPIs, assumptions.

## Prerequisites

PRD must be complete and readable. Understand target architecture: app (UI), domain (business logic), events (event publishing), processor (background jobs).

## Task

Transform PRD into functional and non-functional requirements specifications organized by tier and category.

## Instructions

Follow exact 10-step process:

1. __Analyze Scope & Domain__: Read Scope section. Identify entities, concepts, actors, artifacts, constraints, KPIs, assumptions. Flag out-of-scope items.

2. __Comprehend PRD fully__: Parse every sentence systematically. Create running list of domain concepts, actors, artifacts, constraints, KPIs. Scan for formulas, logic trees, conditional states, UI/UX patterns.

3. __Line-by-line inclusion test__: For each PRD line, decide Include or Ignore. Create coverage ledger (internal; not in output): PRD line ➜ Included/Ignored. Guarantee nothing important is lost.

4. __Deconstruct Logic & Formulas__: For any math formulas or conditional logic, convert to strictly logical requirements. Preserve all operations exactly (e.g., "(A - B) / C * 100"). Make implicit state transitions explicit (e.g., both "Save button disabled" and "Save button enabled" requirements).

5. __Extract UI/UX States & Interactions__: Treat UI element descriptions (buttons, toggles, cards) as functional requirements. Capture "Empty States," "Loading States," "Error States" explicitly. Map interactions to requirements with appropriate tier actor.

6. __Identify Edge Cases & Constraints__: Find "Edge Cases," "Error Handling," "Limitations" sections. Convert each edge case to atomic, tier-specific requirement.

7. __Derive Architectural Categories__: Cluster included items into use-case scenarios or logical buckets (User Lifecycle, Ranking, Ingestion, Security, etc.). Infer sensible categories if PRD doesn't dictate them.

8. __Write Requirements__: For each category, list numbered requirements. Assign unique ID (REQ-FUNC-001, REQ-OPS-005, etc.). Generate 2–5 word descriptive title. Prefix with RFC 2119 keyword. Assign tier token (app, domain, events, processor). Keep atomic, testable, ≤2 sentences.

9. __Separate Sections__: Functional Requirements (behavior, business logic, calculations, UI, data, edge cases). Operational Requirements (performance, scalability, availability, security, observability, compliance, UX, accessibility, maintainability). Group by architectural category within each section.

10. __Quality Checks__: Verify all must/must-not are mandatory/unambiguous. Verify should/should-not include rationale. No dangling pronouns. No duplicates. Each requirement atomic. Formulas preserved exactly. Implicit requirements explicit. Coverage ledger complete (internally). Every PRD line maps to requirement. Every requirement actor is valid tier token.

## Workflow

```
Analyze Scope
└─ Comprehend PRD fully
   └─ Line-by-line inclusion test
      └─ Deconstruct Logic & Formulas
         └─ Extract UI/UX States & Interactions
            └─ Identify Edge Cases & Constraints
               └─ Derive Architectural Categories
                  └─ Write Requirements
                     └─ Separate Sections
                        └─ Quality Checks
```

## Constraints

Use RFC 2119 keywords exactly (must, must not, should, should not, may; all lowercase). Each requirement must describe ONE single behavior or logic gate (atomic). No ambiguous words (appropriately, as needed, user-friendly). Formulas and logic preserved exactly as stated, not summarized. Implicit states made explicit. All tier tokens must be one of: app, domain, events, processor. No PRD verbatim copying unless quoting. No requirement duplicates. Each should/should-not must include rationale in parentheses.

## Standards

RFC 2119: Use of the Words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, and OPTIONAL in Requirement Specifications (https://tools.ietf.org/html/rfc2119)

## Output Format

Markdown document with structure:

```
# Specification: [PRD Title]

## Functional Requirements

### Category A (e.g., User Lifecycle)
1. __REQ-FUNC-001: Friendly Name__: App must <action> (reason)
2. __REQ-FUNC-002: Friendly Name__: Domain must <action>
3. __REQ-FUNC-003: Friendly Name__: Events should not <action> (reason for should-not)
...

### Category B
...

## Operational Requirements

### Performance
1. __REQ-OPS-001: Friendly Name__: App should <action> (reason)
2. __REQ-OPS-002: Friendly Name__: Domain must <action>
...

### Security
...

## Open Questions
- [ ] __[Topic]__: [Quote ambiguous/conflicting text]. *Question for Product Owner.*
...

## Commentary
*(Optional: architectural decisions, trade-offs, further design work)*
```

## Validation

- [ ] All FUNC and OPS requirements have IDs (REQ-FUNC-### or REQ-OPS-###)
- [ ] Each requirement has 2–5 word friendly name
- [ ] Each requirement has RFC 2119 keyword (lowercase)
- [ ] Each requirement has one of four tier tokens (app, domain, events, processor)
- [ ] Each should/should-not has rationale in parentheses
- [ ] No requirement duplicates
- [ ] Each requirement is atomic (one behavior or logic gate)
- [ ] All PRD lines accounted for in coverage ledger
- [ ] All formulas and logic preserved exactly
- [ ] All implicit states explicit

## Clarifying Questions

Ask if: PRD scope unclear (what's in/out of scope?); tier actor ambiguous for requirement (which tier owns this logic?); formula/logic ambiguous (can you clarify the exact calculation?); contradictions found (which version is correct?).

## Examples

__Input:__ PRD for a "Refund Request Feature" with refund amount, tax calculations, eligibility logic, UI states, edge cases (insufficient balance, fraud block, etc.).

__Output:__ Markdown spec with REQ-FUNC-001 through REQ-FUNC-012 (functional: calculations, state transitions, eligibility, edge cases) and REQ-OPS-001 through REQ-OPS-005 (operational: performance, security, observability). Each calculation preserved exactly from PRD. Both "Refund available" and "Refund blocked" states explicitly specified. Open Questions section flags ambiguous fraud logic.

## References

- https://tools.ietf.org/html/rfc2119 (RFC 2119 keywords)

## Non-Goals

Do not implement. Do not design the system architecture. Do not create UI mockups. Do not generate test cases (separate prompt).

## Appendices
  RFC 2119 Keywords (use lowercase in requirements):
  - must: Absolute requirement; mandatory
  - must not: Absolute prohibition; forbidden
  - should: Strong recommendation; include rationale if not done
  - should not: Strong recommendation against; include rationale if done
  - may: Optional; use for flexibility or open questions
  
  Architectural Tier Tokens:
  - app: User-facing application (UI, interactions, state management)
  - domain: Business logic, calculations, validations, state machines
  - events: Event publishing, event schema, async communication
  - processor: Background jobs, batch operations, event processing
  
  Requirement ID Conventions:
  - REQ-FUNC-### for functional requirements
  - REQ-OPS-### for operational requirements
  - ### is zero-padded three-digit number (001, 002, ..., 999)
  
  Common Categories (suggestions):
  - Functional: User Lifecycle, Calculations & Formulas, UI/UX Interactions, Data & State, Edge Cases & Error Handling, Security & Compliance
  - Operational: Performance, Scalability, Availability, Security, Observability, Compliance, UX, Accessibility, Maintainability
  
  Quality Checklist:
  - [x] All requirements have RFC 2119 keyword (lowercase)
  - [x] All requirements have tier token (app, domain, events, processor)
  - [x] Each requirement is atomic (one behavior or logic gate)
  - [x] Each should/should-not has rationale in parentheses
  - [x] No ambiguous words or dangling pronouns
  - [x] Formulas and logic preserved exactly from PRD
  - [x] Implicit state transitions made explicit
  - [x] Coverage ledger complete (all PRD lines accounted for)
  - [x] No duplicate requirements
  - [x] Open Questions section populated with ambiguities
  
  Example Requirement (from PRD: "Save button is disabled until user enters a value"):
  - REQ-FUNC-045: __Save Button State (Disabled)__: App must render Save button in disabled state when input field is empty.
  - REQ-FUNC-046: __Save Button State (Enabled)__: App must render Save button in enabled state when input field contains at least one character.
