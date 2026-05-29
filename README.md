# md-sdlc-wf

Engineer-side SDLC pipeline plugin for [Claude Code](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview), built for the Mudah engineering team.

> **📖 Visual walkthrough + benefits demo:** [sdlc-pipeline-docs.vercel.app](https://sdlc-pipeline-docs.vercel.app)
>
> Tabs: Overview · Benefits (before/after) · Pipeline · Skills · Agents · Who Adopts · **Adoption Guide** · Install.
>
> Full adoption playbook lives in [`ADOPTION.md`](./ADOPTION.md) — two-week pilot shape, squad/vertical/org rollout, common objections, exit ramp.

Turns a Confluence PRD into a grounded implementation handoff: parses the spec → reads Figma → loads repo-aware context → hands off to the project's implementation agent AC-by-AC. After implementation, a local AC coverage check runs against the branch.

This is **Layer 0 + Layer 5** that chips into any repo's existing `.claude/` defect filter — it adds *intent capture* upstream and *AC coverage* downstream, leaving rules / hooks / lint / code-review untouched.

---

## Install

```bash
/plugin marketplace add MD-Sean/WTF
/plugin install md-sdlc-wf
```

Verify:

```bash
/plugin list
# md-sdlc-wf@0.1.0 — installed
```

## Required MCP servers

Configure via `/mcp` in Claude Code. You'll be prompted to authenticate on first use.

| Server | Required | Used by |
|---|---|---|
| `claude_ai_Atlassian` | yes | `spec-digester` (Confluence + Jira) |
| `figma` | optional | `figma-reader` (graceful degrade if absent) |

Without `claude_ai_Atlassian`, `/digest-spec` and `/pilot` cannot run.

## Safety hooks

The plugin ships a `PreToolUse` hook that blocks dangerous Bash commands in any Claude Code session running in this repo:

| Pattern | Blocked |
|---|---|
| `rm -rf /`, `rm -rf ~` | Destructive filesystem wipes |
| `git push --force main/master` | Force-push to protected branches |
| `git reset --hard`, `git checkout -- .`, `git clean -fd` | Destructive git operations |
| `curl \| /bin/bash`, `wget \| /bin/sh` | Remote code execution via pipe |

Hook lives at `.claude/hooks/block-dangerous.sh`, wired in `.claude/settings.json`. Heredoc bodies (commit messages, inline scripts) are stripped before pattern matching to avoid false positives.

---

## Usage

### `/digest-spec <Confluence URL>`

Solo PRD reader. Fast dense summary — title, status, AC table, scope, links. ≤100 lines. No side effects.

```
/digest-spec https://701search.atlassian.net/wiki/spaces/MUGS/pages/4845633585
```

Loud warning if spec status is `Draft` or `Unknown`.

### `/pilot <PRD-url-or-Jira-epic>`

Full upstream pipeline:

1. Digest the PRD via `spec-digester`
2. Read Figma via `figma-reader` (parallel)
3. Optionally extract an ADR stub from the spec's "Technical Approach" section
4. Group ACs by platform + design ref
5. Load repo-aware context per group via `context-loader`
6. Hand off each AC group to the project's implementation agent (one at a time, human-paced)

Halts at every phase boundary. State persists in `.pilot/<spec-id>/` so you can resume.

```
/pilot https://701search.atlassian.net/wiki/spaces/MUGS/pages/4845633585
```

Does **not** create Jira tickets, write tests autonomously, enforce PR title format, or run in CI.

### `/qa-check <branch-or-PR>`

Pre-merge AC coverage gate (local, advisory). Resolves the linked spec, finds which ACs are claimed by tests in the branch's changed files, and verifies the tests actually exercise each AC's Given/When/Then. Renders a coverage report with PASS / WARN / FAIL.

```
/qa-check feature/MDP-580-related-grid-dweb
/qa-check https://github.com/<org>/<repo>/pull/<num>
```

This is **not** a code review. Code quality stays with whatever code-review agent your project already uses.

---

## Components

### Agents (6 — 4 new + 2 bundled)

**New — added by the plugin:**

| Agent | What it does |
|---|---|
| `spec-digester` | Parses a Confluence PRD into canonical JSON. Layout-agnostic — handles both numbered and thematic PRD styles. Caches with `confluence_version_id` for drift detection. |
| `figma-reader` | Pulls cover-frame screenshot, design tokens used, component instances mapped to Code Connect, and sub-frame inventory. Read-only. Degrades when Figma MCP absent. |
| `context-loader` | Produces a markdown context pack per AC group: project rules to honor, ranked relevant files (≤15), prior related PRs (≤5), test patterns to mimic (≤3). |
| `qa-validator` | Verifies AC coverage on a branch. For each AC: finds tests claiming coverage, statically verifies they exercise the scenario, surfaces gaps + orphan tests. |

**Bundled — so the pipeline is complete out of the box:**

| Agent | What it does |
|---|---|
| `senior-frontend-engineer` | Implementation agent. Receives the per-AC-group handoff from `/pilot`, writes code under the project's existing rules + hooks + TDD discipline. Pre-configured for Next.js 16 + React 19 + TypeScript strict + Mantine 8 + Tailwind 4. Adopters on a different stack should fork the prompt to match. |
| `senior-code-reviewer` | Quality reviewer. Audits implementation for race conditions, stale closures, SSR correctness, missing cleanup, perf, security, project rule adherence. *Not* AC coverage — that stays with `qa-validator`. |

Bundled agents are shipped so a fresh repo can run the full pipeline without already having these. If your repo already defines agents with these names, Claude Code's standard precedence loads your project versions over the plugin's — repo-local customizations always win.

All agents are callable solo by name (`"use spec-digester on this URL"`). The skills above are the high-frequency entry points.

### Skills (3)

| Skill | Purpose |
|---|---|
| `/pilot` | Orchestrator. Runs the full upstream pipeline with human checkpoints. |
| `/digest-spec` | Solo PRD read with opinionated rendering policy (≤100 lines). |
| `/qa-check` | Local AC coverage gate with PASS / WARN / FAIL thresholds. |

---

## State + filesystem

The pipeline writes scratch state to `.pilot/<spec-id>/` in whichever repo you run it from:

```
.pilot/
└── <spec-id>/
    ├── digest.json           ← spec-digester output (with confluence_version_id)
    ├── figma.json            ← figma-reader output
    ├── adr.md                ← optional, if PRD has technical-approach section
    ├── context/
    │   ├── G1.md             ← per-AC-group context pack for engineer agent
    │   └── ...
    └── .last-accessed        ← TTL marker (90-day GC after spec status = Done)
```

`/pilot` adds `.pilot/` to your repo's `.gitignore` automatically on first run.

---

## Why this exists

Engineers waste hours per spec on the same chores: scanning 15-page PRDs for AC, cross-referencing Figma, finding which files to touch, mapping AC to tests. The four agents automate the rote parts; the three skills surface them where engineers already work.

This deliberately **does not** automate:

- Story creation in Jira (PM-owned)
- Code review (handled by the project's existing code-review agent)
- Test writing (handled by the project's implementation agent under its TDD discipline)
- PR linkage enforcement (no new hooks, no CI gates)

See `docs/plans/2026-05-26-md-sdlc-wf-design.md` for the full design rationale, including dropped scope and gaps deliberately left un-solved in v0.1.

---

## Versioning

[Semantic versioning](https://semver.org/). Breaking changes in agent output schemas bump major. New optional fields bump minor. Bug fixes + prompt refinements bump patch.

See `CHANGELOG.md`.

---

## Feedback

Internal Mudah team: ping `@kahsing` in Slack or open an issue in the repo.
