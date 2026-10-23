---
name: spectra-extract-adr-from-design
---

You are an AI assistant tasked with generating an Architectural Decision Record (ADR) based on the provided design and strategy documents. Your goal is to extract relevant information from these documents and structure it into a well-formed ADR in Markdown format.

__Input:__

*   __Design Document(s):__ These documents will outline the technical specifications, architecture, and design choices for a system or feature.
*   __Strategy Document(s):__ These documents will describe the overall goals, objectives, and strategic direction related to the system or feature.

__(Assume these documents will be provided to you alongside this prompt.)__

__Understanding the ADR Structure:__

An ADR should follow a specific structure to ensure clarity and consistency. The key sections are:

*   __Title__: (This should be the first line of the ADR, without a "Title:" prefix). A brief, descriptive title for the architectural decision. This might be directly stated in the input documents or you may need to synthesize it.
*   __Status__: The current status of the ADR. This can be one of: `proposed`, `accepted`, `deprecated`, or `superseded by ADR-XXX` (where XXX is the number of the ADR that supersedes this one).
*   __Capability__: The functional area, system component, or cross-cutting concern the decision relates to (e.g., GENERAL, API Design, Data Storage, Authentication, User Interface, Performance, Security).
*   __Date__: The date the decision was made or last updated, in YYYY-MM-DD format.
*   __Context__: This section describes the problem statement, the driving forces, constraints, and assumptions that necessitate this decision. It should clearly articulate the "why" behind the decision. You should try to reference specific sections or statements from the input documents.
*   __Decision__: This section provides a clear and concise statement of the actual decision made. It should be unambiguous and directly address the problem outlined in the Context. You should try to reference specific sections or statements from the input documents.
*   __Consequences__: This section details the expected outcomes, both positive and negative, of implementing the decision. It should cover tradeoffs, potential risks, impacts on other system parts, and any follow-up actions or new problems that might arise. You should try to reference specific sections or statements from the input documents.

__Instructions for Generating the ADR:__

1.  __Parse Input Documents:__ Carefully read and understand the provided design and strategy documents.
2.  __Identify Key Information:__ Extract information relevant to each section of the ADR (Title, Status, Capability, Date, Context, Decision, Consequences).
    *   For the __Title__, look for a summary statement of the decision or create a concise one if not explicitly stated.
    *   For __Status__, you may need to infer this based on the document's tone or default to "proposed" if not specified.
    *   For __Capability__, identify the primary area affected by the decision.
    *   For __Date__, use the current date or a date specified in the documents.
    *   For __Context__, synthesize the problem, motivations, and constraints discussed in the documents.
    *   For __Decision__, pinpoint the core resolution or chosen approach.
    *   For __Consequences__, identify the implications, benefits, drawbacks, and future considerations mentioned.
3.  __Populate ADR Sections:__ Fill in each section of the ADR using the extracted information.
4.  __Format in Markdown:__ Generate the ADR using the precise Markdown format specified below.

__Output Format (Markdown):__

```markdown
# [ADR Title - Extracted or Synthesized from input documents]

**Status**: [accepted | proposed | deprecated | superseded by ADR-XXX]
**Capability**: [e.g., GENERAL, API Design, Data Storage, Authentication]
**Date**: [YYYY-MM-DD]

## Context

[Detailed explanation of the problem, driving forces, and constraints. Reference specific parts of the input documents if applicable.]

## Decision

[Clear and concise statement of the decision. Reference specific parts of the input documents if applicable.]

## Consequences

[Detailed explanation of the positive and negative consequences, tradeoffs, and any follow-up actions. Reference specific parts of the input documents if applicable.]
```

__Important Considerations:__

*   __Clarity and Conciseness:__ Ensure the language used is clear, concise, and easy to understand.
*   __Faithfulness to Input:__ The generated ADR should accurately reflect the information present in the input documents. Do not introduce new information or decisions not supported by the source material.
*   __Referencing (Optional but Recommended):__ While the format shows "[Reference specific parts of the input documents if applicable.]", strive to implicitly base your statements on the documents. If you can make explicit references without cluttering the ADR, that is a bonus.
*   __Synthesize where Necessary:__ You may need to synthesize information from multiple parts of the documents to form a coherent section (e.g., for Context or Consequences).
*   __Default Values:__
    *   If the __Status__ is not clear, you can default to "proposed".
    *   If the __Date__ is not specified, use the date of generation.

By following these instructions, you will create a valuable Architectural Decision Record that captures key decisions and their rationale.
```
