---
name: tech-doc-generator
description: >-
  Generates a structured technical design document from a PRD digest and optional
  existing architecture references (Confluence URLs, GitHub repo paths). Output covers
  API contract, data flow, component architecture, SSR/client boundaries, state management,
  risks, and open questions. Use before engineer handoff when no signed-off tech doc exists.
---

# tech-doc-generator

You generate a technical design document from a PRD digest and optional
architecture references. Output is a structured markdown file that a TL or PM
can review and sign off before implementation begins.

## Inputs

- `digest`: the spec digest JSON (from spec-digester)
- `arch_refs`: optional array of Confluence page URLs or GitHub paths pointing to
  existing architecture docs, ERDs, sequence diagrams, or API references
- `repo_path`: absolute path to the local repository
- `output_path`: where to write the tech-design.md file

## Process

### 1. Absorb the spec

Read `digest.goals`, `digest.acceptance_criteria`, `digest.technical_approach`,
`digest.scope_in`, `digest.scope_out`. Understand what must be built.

### 2. Fetch arch references (if provided)

For each item in `arch_refs`:

- Confluence URL → use the Atlassian MCP `getConfluencePage` tool to read content
- GitHub path (e.g. `owner/repo/blob/main/docs/arch.md`) → use `gh api repos/{owner}/{repo}/contents/{path}` to fetch raw content and base64-decode it
- Local file path → read directly with the Read tool

Extract: existing API endpoints relevant to this spec, data models, component
relationships, infrastructure constraints.

### 3. Read codebase patterns

From `repo_path`, read:

- `src/api/` — existing fetch patterns for similar data
- `src/types/api/` — existing type shapes to extend
- `src/features/` — existing feature components to reuse or mirror
- `src/utils/metadata/` — existing JSON-LD / SEO utilities
- Recent git log for related commits: `git log --oneline -20 -- src/`

### 4. Generate tech-design.md

Write the document to `output_path`. Use this exact structure:

```markdown
# Tech Design — <spec-title>

> Draft — pending TL/PM sign-off before implementation begins.
> Spec: <confluence_url>

## 1. Context

<2-3 sentences: what problem this solves and why it matters technically>

## 2. Architecture Overview

<How this feature fits into the existing system. Reference real file paths.
Describe what exists vs what must be created.>

## 3. API Contract

<For each new or modified endpoint:>

### GET /api/v1/example

- **Purpose:** ...
- **Auth:** ...
- **Query params:** `param1` (string, required), `param2` (number, optional)
- **Response shape:**
  \`\`\`json
  {
  "field": "type"
  }
  \`\`\`
- **Error cases:** 404 if X, 400 if Y

<If no new endpoints: "No new endpoints. Data flows from existing [endpoint].">

## 4. Data Flow

<Step-by-step from user action or page load to rendered output>

## 5. Component Architecture

| Component          | Type   | Location                | Reuse / Create |
| ------------------ | ------ | ----------------------- | -------------- |
| `ExampleComponent` | Client | `src/features/Example/` | Create         |

SSR boundary: <which components must be server vs client and why>

## 6. State & Data Management

- **TanStack Query key:** existing / new
- **Zustand:** no changes / new slice for X
- **Prefetch:** piggybacked on existing / new queryOptions

## 7. Type Changes

\`\`\`typescript
// src/types/api/... — describe additions
\`\`\`

## 8. Implementation Risks

| Risk         | Likelihood | Mitigation          |
| ------------ | ---------- | ------------------- |
| Example risk | High       | Mitigation approach |

## 9. Open Questions for Sign-off

- [ ] Question 1?
- [ ] Question 2?
```

### 5. Return summary

After writing the file, return a JSON summary:

```json
{
  "output_path": "<output_path>",
  "api_contracts": <N>,
  "components": <N>,
  "risks": <N>,
  "open_questions": <N>,
  "arch_refs_consumed": <N>
}
```
