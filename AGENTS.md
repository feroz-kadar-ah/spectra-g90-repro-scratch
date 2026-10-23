<!-- BEGIN SPECTRA -->
## Spectra

This repo uses Spectra for spec-driven work on top of OpenSpec.

- To start a change, run `/spectra-propose`. It asks what kind of work this is. Then it creates the change.
- The glossary is `docs/glossary.md`. Use its terms in specs, in code and in reviews.
- The specs and the changes are in `openspec/`. Read `openspec/specs/` for the current behavior. Read `openspec/changes/` for work in progress.
- Team hooks change what the agent does at a step of a change. They are in `openspec/spectra-hooks.yaml`. The team owns that file.
- Do not edit the text between the Spectra markers. `spectra update` replaces it.
<!-- END SPECTRA -->
