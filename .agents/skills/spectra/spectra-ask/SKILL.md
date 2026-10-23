---
name: spectra-ask
description: Answer which Spectra command to use, when to use it, and how to invoke it. Use when the user runs /spectra-ask or asks what a Spectra skill does.
---

Needs: the installed skill files under `.agents/skills/spectra/`. It needs no network, no tool and no remote.

Identity: `spectra-ask`. Invoke it as `/spectra-ask` or `/spectra-ask <command>`.

This skill answers from the skill files of the repo. It does not run the command that it describes. It does not copy, change or delete a skill. It keeps no list of commands of its own. The files are the only source.

## Where to read

1. Find the `SKILL.md` of every skill folder under `.agents/skills/spectra/`.
2. Read `openspec/.spectra.yaml`, when it exists. Its `vendored` list names third-party skills. Each one sits at `.agents/skills/<name>/SKILL.md`. Read those files too.
3. Use a skill only when its `SKILL.md` can be read. Do not describe a command whose file cannot be read. Do not add a step that the file does not contain.

## What to answer

- __When__ is the `description` in the YAML front matter of the file.
- __How__ is the invocation that the file already states. A file that states no invocation is invoked as `/<name>`, where `<name>` is its `name` field.

Choose the form of the answer from the request.

- The person names no command. Print one list item for each readable skill, including `spectra-ask`. Each item holds the command, then `When:`, then `How:`. Sort the items by command. Do not print a table.
- The person names one command. Answer `When:` and `How:` from that file only.
- The person names something that is not a readable skill. Say that it is not an installed command. List the command names that you read. When the name starts with `openspec-`, say that it belongs to stock OpenSpec and that Spectra does not describe it.
- No `SKILL.md` can be read under `.agents/skills/spectra/`. Say that the Spectra commands are not installed. Name `spectra install`. List no command.

A command that the pack ships but that this repo lacks is missing because the repo has an older release or a damaged install. Say so, and name `spectra update` and `spectra check`.
