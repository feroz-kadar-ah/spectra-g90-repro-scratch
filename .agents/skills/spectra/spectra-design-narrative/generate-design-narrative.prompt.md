---
name: spectra-generate-design-narrative
---

# Generate Design Narrative

To generate an HTML and DOCX design narrative for a set of design documents. Needs `pandoc`. The set sits in one folder, called `<design-dir>` below, and has a name, called `<name>`.

1. Ensure `<design-dir>` contains a `pandoc-html.yaml` defaults file. If it does not exist, ask the person for the list of documents and write the file. The file must:
   - Set `output-file` to `.docs/<name>-design.html` (the `.docs/` folder is gitignored)
   - List all relevant design documents in the correct order
   - Apply consistent formatting and styling
2. From within `<design-dir>`, run:
   ```sh
   cd <design-dir> && pandoc --defaults=pandoc-html.yaml || {
       echo "ERROR: Pandoc failed to generate HTML"; }
   ```
3. Generate the DOCX (output also to `.docs/`). Use the reference document that the person names with `--reference-doc`. When the person names none, omit that option and say so.
   ```sh
   cd <design-dir> && pandoc .docs/<name>-design.html \
       --from=html \
       --to=docx \
       --resource-path=".:images:styles" \
       --embed-resources \
       -o .docs/<name>-system-design.docx  || {
       echo "ERROR: Pandoc failed to generate DOCX"; }
   ```

Report the paths of the two files that you wrote.
