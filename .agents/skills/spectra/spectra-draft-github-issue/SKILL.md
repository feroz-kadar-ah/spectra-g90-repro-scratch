---
name: spectra-draft-github-issue
description: Drafts well-structured GitHub issues in the repository that the person names, or in the repository of the current checkout. Use when creating design tasks, features, epics, or implementation work-items that need motivation (objective, use cases, scope), approach (constraints, deliverables, acceptance criteria), and references.
---

Needs: GitHub access (an MCP server or `gh`), and the repo in which to file the issue. It defaults to the `origin` remote; pass `repo=<owner>/<repo>` for another.

## Repo values

Read the repo when the skill starts. Do not store it in a file or a config key. Run `git remote get-url origin`. Take the owner and the repo name from the URL. The `https`, `scp` and `ssh` forms are valid, with or without `.git`. When the remote is missing or has another shape, use the argument `repo=<owner>/<repo>`. When neither gives a value, say so and stop.

## Procedure

1. Search the open issues of the repo for the same topic before you draft. When you find a match, show it and ask whether to continue.
2. Draft the issue with these sections, in this order: Motivation (objective, use cases, scope), Approach (constraints, deliverables, acceptance criteria) and References.
3. Write each acceptance criterion so that a reviewer can check it. Do not invent names, dates or figures that the input does not state.
4. Show the draft and wait for approval. Do not create the issue before the person approves.
5. Create the issue in the repo. Report its number and URL.

## Bundled prompts

Load one of these files when the task matches. The files are in this folder.

- `extract-epics-from-design.prompt.md`: Decompose a design narrative into independently valuable epics for cross-functional teams.
