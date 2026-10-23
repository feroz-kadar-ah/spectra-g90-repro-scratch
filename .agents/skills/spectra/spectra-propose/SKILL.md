---
name: spectra-propose
description: Start a change on the right Spectra schema. Asks once what kind of work this is (a new feature, a bug fix, or specs for existing code), then runs `openspec new change` with the matching schema. Use at the start of any change. Also use when the user says "spectra propose".
allowed-tools: Bash(openspec:*)
---

Needs: `openspec` on PATH, and a repo where `spectra install` has run (`openspec list --json` shows a root).

Identity: `spectra-propose`. Invoke it as `/spectra-propose`.

This skill picks the Spectra schema for a new change and creates the change on that schema. OpenSpec fixes the schema of a change when it creates the change, so the choice must come before `openspec new change`.

The skill is optional. A change that is created without it uses the default schema, `spectra-default`.

## The three schemas

- `spectra-default`: a new feature or a product change. The artifacts are proposal, specs, design and tasks.
- `spectra-bug-fix`: a defect. The artifacts are a bug report with the reproduction and the expected behavior, the delta specs, and tasks that hold the fix and a regression test.
- `spectra-bootstrap-specs`: existing code that has no specs. The artifacts are a survey, baseline specs and a review that lists the gaps. It has no tasks.

## Steps

1. Read the input.

   The input can hold a change name or a description of the work. It can also hold `--schema <name>`.

   If the input names a schema with `--schema`, use it and go to step 3. Accept only `spectra-default`, `spectra-bug-fix` and `spectra-bootstrap-specs`. For any other value, say which three are valid and ask the question in step 2.

2. Ask what kind of work this is. Ask once.

   Offer these three answers:
   - New feature or product change (`spectra-default`)
   - Bug fix (`spectra-bug-fix`)
   - Bootstrap specs for existing code (`spectra-bootstrap-specs`)

   If the input has no description of the work, ask for it in the same message. Do not ask a second question about the kind of work. If the person's answer is unclear, choose `spectra-default` and say so.

3. Check the project.

   Run `openspec list --json` and read `root`. If `root` is null, stop. Tell the person to run `spectra install`. Do not run `openspec init`.

   Run `openspec schema which <schema>`. If the schema does not resolve, stop. Tell the person to run `spectra install`, then `spectra check`.

4. Derive the change name.

   Use kebab-case. Example: "fix duplicate payout" becomes `fix-duplicate-payout`. If a change with that name exists, ask whether to continue it or to create a new one. Do not create a change with the same name.

5. Create the change.

   ```bash
   openspec new change "<name>" --schema "<schema>"
   ```

   Do not edit `.openspec.yaml`. Do not create a change on a schema that the person did not choose.

6. Show the artifact order.

   ```bash
   openspec status --change "<name>" --json
   ```

   Tell the person the schema, the artifact IDs in build order, and which artifact is ready.

7. Create the artifacts.

   Continue as the `openspec-propose` skill does, from its step "Get the artifact build order". The change exists, so do not create it again. For each ready artifact:
   - Run `openspec instructions <artifact-id> --change "<name>" --json`.
   - Follow `instruction` and `template`. Apply `context` and `rules` as constraints. Do not copy them into the file.
   - Read the files of the dependencies from disk before you write.

   Create every artifact that the apply phase needs, directly or through other artifacts.

## Guardrails

- This skill plans only. Do not edit project code. After the artifacts exist, stop and wait for a new request to apply the change.
- Do not change the `schema` value in `openspec/config.yaml`.
- Do not ask which schema to use more than once.
