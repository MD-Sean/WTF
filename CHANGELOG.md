# Changelog

All notable changes to `md-sdlc-wf` documented here. Follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) + [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] — 2026-05-27

Initial release. Designed for the Mudah `md-auto-web` stack but repo-agnostic where possible.

### Added

- Agent `spec-digester` — Confluence PRD → canonical JSON. Handles numbered (PRD-1 style) and thematic (PRD-2 style) layouts. Caches with `confluence_version_id` for drift detection.
- Agent `figma-reader` — read-only Figma context extractor. Cover frame screenshot + tokens + Code Connect mapping + sub-frame inventory. Graceful degrade when Figma MCP unavailable.
- Agent `context-loader` — produces per-AC-group markdown context pack distilled from `.claude/rules/`, ranked repo files (≤15), prior PRs (≤5), test patterns (≤3).
- Agent `qa-validator` — static AC coverage analysis. Per-AC: covered / partial / uncovered with reasons. Orphan test detection. Advisory only, not a merge gate.
- Bundled agent `senior-frontend-engineer` — implementation agent invoked by `/pilot` for per-AC-group handoffs. Pre-configured for Next.js 16 / React 19 / TypeScript strict / Mantine 8 / Tailwind 4. Adopters on a different stack fork the prompt to match.
- Bundled agent `senior-code-reviewer` — quality reviewer for race conditions, SSR, cleanups, perf, security. Bundled so the pipeline ships complete; repo-local versions of the same name take precedence per Claude Code's standard loader.
- `ADOPTION.md` — full adoption playbook with two-week pilot shape, squad/vertical/org rollout, common objections, success indicators, and exit ramp.
- Skill `/pilot` — orchestrator. Digest → Figma → ADR stub → AC grouping → context loading → handoff to `senior-frontend-engineer` per group with human checkpoints.
- Skill `/digest-spec` — solo PRD reader. ≤100 line opinionated render with status warnings + warning code translation.
- Skill `/qa-check` — local AC coverage gate. PASS / WARN / FAIL thresholds (>30% uncovered = FAIL). Per-platform refinement warnings (functional / UI / server).
- Plugin manifest at `.claude-plugin/plugin.json` for marketplace install.

### Not in scope for 0.1.0 (see `docs/plans/2026-05-26-md-sdlc-wf-design.md` § "Out of scope")

- Story planning / Jira ticket creation
- PR title linkage enforcement
- CI-side qa-check
- Idempotency lock + pilot rollback
- Feature flag wiring suggestion
- Analytics / instrumentation story proposal
- Spec-PR version pinning in PR template
- Bilingual content normalization (MS + EN)
- Cost budget cap + telemetry
- Story de-dup against Jira backlog
- `pilot sync-ac` mid-build drift checker
- Test scaffolding (TDD handled by `senior-frontend-engineer`)
- Cross-repo coordination (Route 2 — preserved via `target_surfaces[]` field, not wired)
