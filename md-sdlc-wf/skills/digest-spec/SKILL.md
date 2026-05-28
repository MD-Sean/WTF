---
name: digest-spec
description: >-
  Solo PRD reader. Takes a Confluence URL or page ID and renders an opinionated, dense, engineer-friendly digest: title + status + one-paragraph summary + AC table + out-of-scope + Figma/Jira links + rollback triggers if present. Calls the spec-digester agent and applies render policy. Triggers: "/digest-spec", "summarize this PRD", "what's in this Confluence spec".
---

# /digest-spec — Solo PRD Read

You render a fast, dense, human-readable summary of a Confluence PRD. You call the `spec-digester` agent to do the heavy lifting; your job is the formatting policy.

## Input

A single argument: Confluence URL or page ID.

If absent: ask once. Do not guess.

## Process

1. Dispatch `spec-digester` agent with the URL/ID.
2. When the agent returns JSON, render to terminal per the policy below.
3. Do not save additional files — the agent caches the digest itself.

## Render Policy

**Cap output at 100 lines total**. Brevity is the product. If the spec is large, truncate AC table tail with `… (N more, see digest.json)`, never collapse the summary or out-of-scope.

### Required sections, in this order:

```
═══════════════════════════════════════════════════════════════════
<spec-id or page-id> · <title>
Status: <status>   Figma: <yes/no>   Epic: <key or "—">
═══════════════════════════════════════════════════════════════════

ONE-LINER
<2-3 sentence problem + outcome summary. Distilled from the digest's "problem" + "goals" fields. Engineer should know what this is in 10 seconds.>

ACCEPTANCE CRITERIA (<N>)
┌──────┬─────────────┬───────────────────────────────────────────┐
│ ID   │ Platform    │ Scenario                                   │
├──────┼─────────────┼───────────────────────────────────────────┤
│ AC-01│ Functional  │ <scenario, truncate to ~50 chars>          │
│ ...  │ ...         │ ...                                        │
└──────┴─────────────┴───────────────────────────────────────────┘

OUT OF SCOPE
- <each scope_out bullet, verbatim>

SUCCESS METRICS
- <metric_name>: <target> (<timeframe>) · source: <source or "—">
- ...

ROLLBACK TRIGGERS                         (only if digest has any)
- <trigger> → <action> (threshold: <threshold>)
- ...

LINKS
Figma:   <each figma_link, one per line, with frame node id if present>
Jira:    <epic_key or "—">
Related: <each related_doc, one per line>

⚠ WARNINGS
- <each warning from digest, in plain English — see translation table below>
```

### Status Warning

Render status loudly:

- `Signed` / `Building` / `Done` → no banner
- `In-Review` → render `⚠ Spec is In-Review (not yet Signed). AC may shift before final.`
- `Draft` → render `⚠⚠ Spec is DRAFT. Do not implement yet — AC will change.`
- `Unknown` → render `⚠ Spec status could not be determined.`
- `Rolled-back` → render `⚠ Spec was rolled back. Coordinate with PM before resuming.`

### Warning Translation

The digest's `warnings[]` field contains short codes. Translate to plain English:

| Code | Render as |
|---|---|
| `status_inferred` | "Status was inferred from page state, not declared explicitly." |
| `no_acceptance_criteria` | "Spec has NO acceptance criteria — engineer cannot work safely from this." |
| `figma_missing_but_ui_scope` | "Spec describes UI but no Figma link present." |
| `metrics_unmeasurable` | "Metrics defined but no measurement source — KPIs untrackable as written." |
| `spec_drifted` | "Spec changed since last cached read — digest auto-refreshed." |
| `unstructured_prd` | "PRD lacks standard heading structure — extraction is best-effort." |
| `mcp_offline_served_cache` | "Atlassian MCP offline; showing cached digest (may be stale)." |
| `status_draft` | (covered by Status Warning above) |

### Absent Sections

If a section's source data is empty, omit the section header entirely. Do not render `OUT OF SCOPE` with a `(none)` placeholder. Skip the header.

Exception: `ACCEPTANCE CRITERIA` is required. If empty, render the header with a single row `│ — │ — │ No AC defined in spec. │` and add a top-line ⚠ warning.

## Failure Modes

- `atlassian_mcp_offline` and no cache → print `"Atlassian MCP offline and no cached digest available. Try again or use the Confluence URL when MCP returns."`
- `page_not_found` → print `"Page <id> not found. Check the URL and that you have access."`

## What You Do NOT Do

- Do not run the full `/pilot` pipeline. This is a read-only summary.
- Do not call `figma-reader` or `context-loader`. Only `spec-digester`.
- Do not write files (the agent caches its digest; the skill just renders).
- Do not interpret or judge the spec quality — render what the agent returned.
- Do not exceed 100 lines. Engineers want to skim, not read.
