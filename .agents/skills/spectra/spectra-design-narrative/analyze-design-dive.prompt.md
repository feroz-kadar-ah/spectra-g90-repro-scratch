---
name: spectra-analyze-design-dive
---

# Analyze Design Dive

You are an expert system designer. Your task is to analyze a specified Design Dive document against the repository's Design Dive standard.

## Repo values

Read these when the skill starts. Do not store them in a file or a config key.

- Standards source: the argument `standards=<directory or URL prefix>`, or else the `standards/` directory at the repo root. Find the design dive standard by its topic. When the repo has a git remote, link a standard by the absolute URL `https://<host>/<owner>/<repo>/blob/<branch>/standards/<file>`, with the values from `git remote get-url origin` and `git symbolic-ref --short refs/remotes/origin/HEAD`.
- When no standards source exists, or it holds no design dive standard, print `No standards source found. Pass standards=<directory or URL prefix>.` and stop. Never guess what the standard says.

## Context

The developer will provide a path to a Design Dive document. You must read this document and the Design Dive standard from the standards source.

## Instructions

1.  __Read the Standard__: Review the requirements and anatomy specified in the Design Dive standard.
2.  __Analyze the Document__: Evaluate the provided design dive document for conformance to the standard.
3.  __Identify Gaps__: Highlight any missing sections, inconsistent use of RFC 2119 verbs, or deviations from the prescribed anatomy.
4.  __Evaluate Technical Depth__: Assess whether the technical specification (data structures, logic, interfaces) is detailed enough for implementation.
5.  __Check Traceability__: Verify if the dive references higher-level system documentation as required.
6.  __Provide Recommendations__: Suggest specific improvements to bring the document into full compliance with the standard.

## Output Format

-   __Conformance Summary__: A brief overview of how well the document aligns with the standard.
-   __Detailed Gap Analysis__: A list of specific areas where the document falls short, organized by the sections defined in the anatomy.
-   __Suggested Edits__: Propose specific text or structure changes to address the identified gaps.
-   __Action Items__: A concise list of tasks for the developer to complete the document.

Do not replicate the content of the standard itself in your response; refer to the sections and rules defined in the Design Dive standard, and link it by its absolute URL.
