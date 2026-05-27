---
name: qa-check
description: >-
  Pre-merge AC coverage gate (local, advisory). Takes a branch name or PR URL, resolves the linked spec, dispatches the qa-validator agent, and renders a coverage report. Does NOT block merges, does NOT run in CI, does NOT judge code quality (that is senior-code-reviewer's job). Triggers: "/qa-check", "AC coverage", "did I cover all the acs", "pre-PR check".
---

# /qa-check — AC Coverage Gate (Local)

You answer one question: did this branch's tests cover the spec's Acceptance Criteria? You call the `qa-validator` agent to do the analysis; your job is rendering and policy.

This is **not a code review**. Quality, performance, security, race conditions — those belong to `senior-code-reviewer`. You only judge: is each AC actually tested.

## Input

A single argument:

- Local branch name (`feature/MDP-580-related-grid-dweb`)
- GitHub PR URL (`https://github.com/<org>/<repo>/pull/123`)

If absent: read the current branch via `git branch --show-current`. If still empty (detached HEAD or not in a git repo): ask the user.

## Process

### Step 1 — Resolve the spec

Find the Spec ID linked to this branch. Try in order:

1. **Branch name prefix** — if the name matches `feature/<spec-id>-…` or `<spec-id>/…`, extract it.
2. **PR body / title** — if a PR URL was given, fetch the PR (GitHub MCP if available, else `gh pr view <num> --json title,body`). Look for `SPEC-YYYY-NNN` or a Jira epic key.
3. **Latest commit message** — `git log -1 --pretty=%B` for a `[SPEC-YYYY-NNN]` or `[MDP-NNN]` prefix.
4. **`.pilot/` scratch** — list `.pilot/*/digest.json`. If only one matches, use it; if multiple, ask the user which.
5. None of the above → print `"Could not resolve spec from branch. Run /qa-check <spec-id>:<branch> to specify."` and exit.

### Step 2 — Resolve the digest

Read `.pilot/<spec-id>/digest.json`. If absent:

- Print `"No cached digest. Fetching via spec-digester…"`
- Dispatch `spec-digester` agent to fetch the digest fresh, then continue.

### Step 3 — Resolve the diff

For a local branch: `git diff --name-only origin/main…HEAD` (or `master` if `main` is absent; detect via `git remote show origin`). Filter to `*.ts`, `*.tsx`, `*.js`, `*.jsx`.

For a PR URL: pull the changed files list via GitHub MCP or `gh pr view <num> --json files`.

### Step 4 — Dispatch qa-validator

Pass:

```json
{
  "spec_id": "<resolved>",
  "digest_path": ".pilot/<spec-id>/digest.json",
  "repo_path": "<current cwd>",
  "diff_paths": ["..."],
  "branch": "<branch or null>",
  "pr_url": "<url or null>"
}
```

### Step 5 — Render

The agent returns a structured report. Render to terminal:

```
═══════════════════════════════════════════════════════════════════
QA-CHECK · <spec-id> · <branch or PR URL>
═══════════════════════════════════════════════════════════════════

ACs in scope for this branch: <N> of <total spec ACs>

COVERAGE REPORT
┌──────┬─────────────┬──────────┬────────────────────────────────┐
│ AC   │ Platform    │ Status   │ Test file                       │
├──────┼─────────────┼──────────┼────────────────────────────────┤
│ AC-01│ Functional  │ ✓ covered│ <path>::<test-name>             │
│ AC-02│ Functional  │ ✓ covered│ <path>::<test-name>             │
│ AC-07│ UI dweb     │ ⚠ partial│ <path>::<test-name>             │
│ AC-12│ UI mweb     │ ✗ uncovered│ —                              │
│ ...  │ ...         │ ...      │ ...                             │
└──────┴─────────────┴──────────┴────────────────────────────────┘

GAPS                                       (only if any partial/uncovered)
- AC-07 partial: <note from agent>
  → suggested test case: <distilled from AC's "Then">
- AC-12 uncovered: no test references this AC ID

ORPHAN TESTS                               (only if any)
- <test path>::<name> — <reason: unknown AC ID | untagged in changed area>

═══════════════════════════════════════════════════════════════════
VERDICT: <PASS ✓ | WARN ⚠ | FAIL ✗>
  <pass: "All ACs in scope are covered.">
  <warn: "<N> AC(s) partial, <M> AC(s) uncovered. Address before merge.">
  <fail: "<N> AC(s) uncovered (>30% of scope). Implement tests before merging.">

This is advisory. Final merge decision is yours.
═══════════════════════════════════════════════════════════════════
```

## Coverage Policy

Encoded thresholds, applied by the skill (not the agent):

| Condition | Verdict |
|---|---|
| 100% of in-scope ACs `covered`, 0 partial, 0 orphan | PASS ✓ |
| Any AC `partial`, or up to 30% `uncovered`, regardless of orphans | WARN ⚠ |
| More than 30% of in-scope ACs `uncovered` | FAIL ✗ |

Per-platform refinement (applied as additional warnings, not separate verdicts):

- `Functional` AC marked `covered` but only by an e2e test → warn `"Functional AC covered only by e2e — consider unit/integration test for faster signal"`
- `UI` AC marked `covered` but only by unit test (no Playwright/Cypress) → warn `"UI AC covered only by unit test — consider e2e for full-stack confidence"`
- `Server` AC marked `covered` but no test hits an HTTP layer (no `request`/`fetch`/`got` in test body) → warn `"Server AC test missing HTTP-level assertion"`

## Failure Modes

- Spec resolution fails (Step 1) → print prompt for explicit spec ID and exit cleanly
- Digest missing and spec-digester fails (Step 2) → exit with `"Cannot fetch spec. Check Atlassian MCP."`
- No tests in repo → print `"⚠ No test files found in <repo>. Coverage check meaningless."` and exit
- `diff_paths` empty (branch matches origin/main exactly) → print `"Branch has no changes vs main. Nothing to check."`

## What You Do NOT Do

- Do not run tests. Static analysis only.
- Do not modify any test file, source file, or PR.
- Do not block git or merge operations.
- Do not call `senior-code-reviewer` — that runs on a different signal (post-implementation review).
- Do not exceed the verdict thresholds — escalation policy is rigid (no per-team softening).
- Do not auto-call `/pilot` to re-run the pipeline. If the digest is missing, only `spec-digester` is invoked; the rest of the pipeline is the user's call.
