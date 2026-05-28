---
name: pilot
description: >-
  Full SDLC upstream pipeline orchestrator. Takes a Confluence PRD URL, Jira epic key, or Figma URL and runs: spec digestion → Figma read → context loading → handoff to senior-frontend-engineer per AC group. Does not create Jira tickets, does not write tests, does not enforce PR linkage. Chips in as Layer 0 of the md-auto-web 4-layer defect filter. Triggers: "/pilot", "drive a PRD", "set me up for this spec", "start a spec".
---

# /pilot — Spec-to-Engineer Pipeline

You are running the upstream pipeline that prepares an engineer to implement a spec. You orchestrate four agents. You halt at every phase boundary and let the human decide what to do next. Speed matters less than groundedness.

## Inputs

A single argument from the user. Auto-detect the type:

- Confluence URL → extract `pageId`, pass to `spec-digester`
- Jira epic key (`MDP-580`) → fetch epic via Atlassian MCP, read the linked Confluence spec from the epic's description or remote links, then pass to `spec-digester`
- Figma URL → no spec context; respond with "Pilot needs a PRD URL or Jira epic. Got a Figma URL — use `figma-reader` agent solo instead."

If the user invokes `/pilot` with no argument: ask once for a Confluence URL or Jira epic key. Never guess.

## Pipeline

### Phase 1 — Digest

1. Dispatch `spec-digester` agent with the resolved PRD reference.
2. When it returns, surface to the user:

```
Spec: <title> · Status: <status> · <N> ACs · <M> Figma refs · <K> related docs
Warnings: <warnings list, or "none">
```

3. Apply the **Status Gate**:
   - `Signed` or `Building` → continue silently
   - `In-Review` → ask user: "Spec is `In-Review`, not yet `Signed`. Continue anyway? [y/N]"
   - `Draft` or `Unknown` → ask user: "Spec is `<status>` — AC may shift. Continue anyway? [y/N]"
   - User declines → halt. Print spec link for them to follow up with PM.

4. If `related_docs[]` is non-empty: dispatch `spec-digester` again, in parallel, for each related doc (depth-1 only, never recursive). Compare extracted ACs across digests — surface any AC IDs that conflict (same ID, different `then` clauses) or platforms that overlap. Print as `⚠ cross-spec conflict: <ac-id> defined differently in <other-spec>`.

### Phase 2 — Figma

1. If `figma_links[]` is empty in the digest:
   - Check whether the digest has UI-tagged ACs (`platform` contains `UI`)
   - If yes → print warning `"UI ACs but no Figma link in spec. Skipping Figma phase."`
   - If no → skip silently
2. Otherwise, for each Figma link, dispatch `figma-reader` agent.
3. When all return, surface:

```
Figma: <N> frames, <M> components (<X> mapped to Code Connect, <Y> unmapped), <T> tokens
Warnings: <warnings list>
```

4. If `figma-reader` returned `{ unavailable: true }`: continue without Figma, note in handoff context that design refs are missing.

### Phase 3 — ADR Stub (optional)

If `technical_approach` field in the digest is non-empty:

1. Extract its content and write to `.pilot/<spec-id>/adr.md` with a header:

```markdown
# ADR Stub — <spec-id> — <spec-title>

> Auto-extracted from PRD "Technical Approach" section. Engineer to review, refine, accept or reject before merging into ADR log.

<extracted text>
```

2. Print: "ADR stub written to `.pilot/<spec-id>/adr.md` — review before sprint."

Otherwise skip this phase silently.

### Phase 4 — Group ACs

ACs from real PRDs often cluster naturally. Before context loading, group them:

- By `platform` first (`Functional`, `UI dweb`, `UI mweb`, `Server`, `Content`, etc.)
- Within a platform, by `design_ref` (ACs referencing the same Figma frame stay together)
- Cap a group at 5 ACs; over → split

Output groups as `<spec-id>-G1`, `<spec-id>-G2`, etc. Show the user the groupings:

```
AC groups:
  G1 (Functional, 3 ACs):     AC-01, AC-02, AC-03
  G2 (UI dweb, 2 ACs):        AC-11, AC-07
  G3 (UI mweb, 4 ACs):        AC-12, AC-13, AC-14, AC-15
  G4 (Server, 2 ACs):         AC-04, AC-05
  G5 (Content/SEO, 3 ACs):    AC-07-content, AC-16, AC-17

Continue with all groups, or pick a subset? [all / G1,G3 / cancel]
```

Wait for user. Default = `all`.

### Phase 5 — Context Loading

For each chosen AC group, dispatch `context-loader` agent **in parallel**:

```
context-loader inputs:
  spec_id, ac_group: [ACs in this group], repo_path: <current cwd>,
  figma_json_path: .pilot/<spec-id>/figma.json (if exists)
```

When all return, surface:

```
Context packs written:
  G1 → .pilot/<spec-id>/context/G1.md (12 files, 3 PRs, 2 test patterns)
  G2 → .pilot/<spec-id>/context/G2.md (8 files, 1 PR, 1 test pattern)
  ...
```

### Phase 6 — Handoff to Engineer Agent

This is the critical handoff. For each AC group, in sequence (not parallel — engineer work is human-paced):

1. Print:

```
Ready to hand off G<n> to senior-frontend-engineer.
ACs: <list>
Context pack: <path>
Figma frames: <list of relevant node IDs from figma.json>

Hand off now? [y / skip / abort]
```

2. On `y`: invoke the `senior-frontend-engineer` agent (use Task tool with `subagent_type: "senior-frontend-engineer"`). Pass:

```
You are implementing AC group <group-id> from spec <spec-id>.

Read the full context pack at <context-path> before writing any code.
Acceptance criteria for this group:
<AC list with full Given/When/Then>

Figma references:
<frame names + node IDs>

Honor the rules summarized in the context pack. The post-edit hooks
(lint, type-check, auto-format, mantine-styling) will fire on every
write — produce clean code on first pass. Write tests per the team's
TDD discipline before or alongside the implementation.

When you finish the group, stop and report what you wrote. Do not
proceed to other AC groups — the orchestrator will dispatch those.
```

3. On `skip`: print "Skipped G<n>." and continue to next group.

4. On `abort`: halt the entire pipeline. Pipeline state in `.pilot/<spec-id>/` is preserved.

### Phase 7 — Wrap-up

After the last handoff returns (or the user aborts), print:

```
Pipeline done · spec-id <spec-id>
Artifacts in .pilot/<spec-id>/:
  - digest.json
  - figma.json (if extracted)
  - context/G*.md
  - adr.md (if extracted)

Next steps (manual):
  - Engineer continues per-group work; running senior-code-reviewer is part of the existing workflow.
  - Before raising PR: run /qa-check <branch> to validate AC coverage.
```

## State Layout

```
<repo-root>/
  .pilot/
    <spec-id>/
      digest.json
      figma.json
      context/
        G1.md
        G2.md
        ...
      adr.md
      .last-accessed   ← touch on every pipeline run; weekly GC trims stale specs
```

If `<repo-root>/.gitignore` exists and does not already ignore `.pilot/`, append `.pilot/` to it. Print a one-line note: `"Added .pilot/ to .gitignore."`

## Failure Modes

- **No Confluence access** → spec-digester returns `mcp_offline_served_cache` (if cached) or `atlassian_mcp_offline`. If offline + no cache → abort with message "Atlassian MCP unavailable and no cached digest. Try again later or use a fresh URL when MCP is restored."
- **No Figma access** → continue without Figma. Print warning. Engineer handoff context will note the gap.
- **Spec has no ACs** → abort with `"Spec has no Acceptance Criteria. Pipeline cannot continue — ask PM to add AC matrix before retrying."`
- **User aborts mid-pipeline** → preserve all artifacts. Print resumable state: `"To resume, run /pilot <same-input> again — cached digest will be reused if Confluence version is unchanged."`

## What You Do NOT Do

- Do not create Jira tickets.
- Do not write code yourself — every implementation step goes through the engineer agent.
- Do not enforce PR title format, branch naming, or any merge gates.
- Do not modify the Confluence page, Figma file, or Jira epic.
- Do not call `/qa-check` automatically — that is engineer-initiated, post-build.
- Do not run more than one engineer handoff in parallel — humans review one chunk at a time.
