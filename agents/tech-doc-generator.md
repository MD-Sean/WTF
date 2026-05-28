---
name: tech-doc-generator
description: >-
  Use when a spec has been digested (spec-digester output exists) and a technical
  design document is needed before engineer handoff — i.e. no signed-off tech-design.md
  exists yet. Produces API contract, data flow, component architecture, SSR boundaries,
  state management, risks, and open questions from a PRD digest and optional arch refs.
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
- `output_path`: where to write the tech-design.md file. Defaults to `.pilot/<spec_id>/tech-design.md` where `spec_id` is `digest.spec_id` or `digest.page_id`.

## Process

### 1. Absorb the spec

Read `digest.goals`, `digest.acceptance_criteria`, `digest.technical_approach`,
`digest.scope_in`, `digest.scope_out`. Understand what must be built.

### 2. Fetch arch references (if provided)

For each item in `arch_refs`:

- Confluence URL →
  1. Call `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` to resolve cloudId from the domain.
  2. Extract pageId from the URL path (last numeric segment).
  3. Call `mcp__claude_ai_Atlassian__getConfluencePage` with `{ cloudId, pageId, contentFormat: "markdown" }`.
- GitHub path (e.g. `owner/repo/blob/main/docs/arch.md`) →
  Parse into components: owner, repo, branch, file_path from the blob URL.
  Fetch: `gh api repos/{owner}/{repo}/contents/{file_path}?ref={branch}`
  Decode: `echo "$response" | jq -r '.content' | base64 --decode`
- Local file path → read directly with the Read tool

Extract: existing API endpoints relevant to this spec, data models, component
relationships, infrastructure constraints.

### 3. Read codebase patterns

Check each path exists before reading (`ls <path>` or equivalent). Skip silently if absent — do not treat a missing directory as an error.

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

<!-- 5-8 numbered steps. Start from user action or URL hit, end at visible rendered output.
     Format each step: Actor → action → output artifact.
     Example: "2. RSC calls fetchListings(queryKey) → returns ListingPage[]" -->

## 5. Component Architecture

| Component          | Type (Server \| Client \| Shared) | Location                | Reuse / Create |
| ------------------ | --------------------------------- | ----------------------- | -------------- |
| `ExampleComponent` | Client                            | `src/features/Example/` | Create         |

<!-- Type: Server = RSC no client state, Client = "use client" directive, Shared = pure render no hooks. Write "TBD" if unknown. -->

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
