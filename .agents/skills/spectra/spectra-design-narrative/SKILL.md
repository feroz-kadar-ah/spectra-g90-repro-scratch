---
name: spectra-design-narrative
description: Analyze design dives, explain systems in the narrative structure, generate HTML/DOCX narratives, and extract meeting takeaways for design communication.
---

Needs: a design document or a meeting transcript that the person gives you. The analysis prompt also needs a standards source with a design dive standard. The generate prompt needs `pandoc`.

## Bundled prompts

Load one of these files when the task matches. The files are in this folder.

- `analyze-design-dive.prompt.md`: Analyze a design dive document for conformance to the design dive standard.
- `explain-design-narrative.prompt.md`: Explain a design document in the prescribed narrative structure.
- `generate-design-narrative.prompt.md`: Generate HTML and DOCX design narratives with pandoc from a defaults file in the design folder.
- `extract-key-takeaways.prompt.md`: Extract key takeaways from meeting transcripts with supporting evidence, organized by topic for stakeholders.
