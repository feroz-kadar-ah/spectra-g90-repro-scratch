---
name: spectra-install-check
description: |
  Full spectra-default pressure test in <repo>/.sandbox/spectra-install-check/: spectra install,
  check, toy OpenSpec change (proposal through tasks), validate, and archive. Maintainers use a
  local tgz; consumers use a published @earnin/spectra release.
---

Needs: `bun`, `python3` and `openspec` on PATH, and the sandbox script `scripts/install-check-sandbox.sh` from a Spectra checkout. To check a published release it also needs `curl`, `scripts/fetch-release.sh` beside the script, and a token in `GH_TOKEN` or `GITHUB_TOKEN` (the repository is private).

Identity: `spectra-install-check`. Invoke in Cursor as **`/spectra-install-check`**.

Publisher registry: `spectra.config.ts` → `skills.registry` includes `.agents/skills/spectra/spectra-install-check` (same path in this repository and on the consumer). Consumer install copies from the pack manifest `skills[]` list.

## When to use

- Validating Spectra pack/schema/config changes (Spectra maintainers)
- Verifying a **published** `@earnin/spectra` release in any consumer repo
- After the user asks to repeat the spectra-default install-check or pressure test

## Sandbox (required)

All work happens under:

```text
<repo-root>/.sandbox/spectra-install-check/
├── openspec/          # init + spectra install + toy change + archived specs
├── .agents/skills/
├── docs/glossary.md
└── run.log
```

`.sandbox/` is gitignored — nothing here is committed. Each run **recreates** the sandbox directory.

There is no shallow mode: always **install → check → toy change → validate --strict → archive**.

## Spectra package (maintainers vs consumers)

| Who | How `spectra` is resolved | Override |
|-----|-------------------------|----------|
| **Maintainer** (repo root has a `package.json` named `@earnin/spectra`) | Build the package, `bun pm pack`, install via `bun x -p file:…tgz` | `SPECTRA_PACKAGE=file:/abs/path.tgz` (run with `-p`) |
| **Published release** (any root) | Download the GitHub release with `scripts/fetch-release.sh` (sums, sizes, digest), install via `bun x -p file:…tgz` | `SPECTRA_RELEASE=<version>` |
| **Consumer** (service repo, no `@earnin/spectra` package at its root) | The published release `SPECTRA_VERSION` (the registry is off for now) | `SPECTRA_VERSION=<version>`, or `SPECTRA_PACKAGE=@earnin/spectra@<version>` for a registry that holds it |

To test the upgrade that a consumer takes, run `make run-upgrade-check FROM=<old> TO=<new>`: the old release installs a repo, and the CLI of the new release updates it. `SPECTRA_PACKAGE` wins over `SPECTRA_RELEASE`, and `SPECTRA_RELEASE` wins over the maintainer build. In a Spectra checkout, `make run-install-check-release VERSION=<version>` downloads, verifies the pack and runs the check in one command. A copy of the script outside a checkout needs `SPECTRA_VERSION` or `SPECTRA_RELEASE`, and `fetch-release.sh` beside it.

Prerequisites on `PATH`: `openspec` (stock init), `bun`, `python3` (assertions in the runner).

## Procedure

1. `cd` to the **repo root** where you want the sandbox (the Spectra repository or a consumer service repo).
2. Run:

   ```sh
   bash scripts/install-check-sandbox.sh
   ```

   From a consumer repo without that path, copy the script or set `SPECTRA_INSTALL_CHECK_ROOT` and invoke the script by absolute path from a Spectra checkout.

3. Optional environment:

   - `SPECTRA_INSTALL_CHECK_ROOT` — repo root (default: git top-level or cwd)
   - `SPECTRA_INSTALL_CHECK_SANDBOX` — default `<root>/.sandbox/spectra-install-check`
   - `SPECTRA_INSTALL_CHECK_CHANGE` — toy change id (default `toy-spectra-pressure`)
   - `SPECTRA_PACKAGE` — force package source (see table above)
   - `SPECTRA_RELEASE` — check the published release of this version
   - `SPECTRA_VERSION` — the release that a consumer run checks by default

4. On success, cite `run.log` evidence:
   - `schema: spectra-default`, `spectra check` OK, `openspec schema validate spectra-default`
   - `openspec instructions proposal --json`: Spectra preamble + tagged rules
   - `openspec validate <change> --strict` OK
   - `openspec archive <change> -y` OK and `openspec/specs/toy-widget/spec.md` exists in the sandbox

5. On failure, fix **the Spectra package** or the release package — do not hand-edit the sandbox as the durable fix.

## Out of scope

- Live grill interview (proposal is written as post-grill simulation)
- Cursor/Claude symlink deploy (FR-9.22) — install copies only under `.agents/skills/…`
- Comment-preserving config merge, `spectra update`, or multi-schema packs
