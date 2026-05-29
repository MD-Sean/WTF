# Adoption Guide — md-sdlc-wf

How to roll this plugin out to a team without forcing it. Designed for a 15+ engineer team across multiple verticals. Plays well with any adoption level — one engineer, one squad, one vertical, or org-wide.

---

## Adoption gradient

You don't need a top-down mandate. The plugin earns its keep at every adoption level.

| Level | Who needs to opt in | Value unlocked |
|---|---|---|
| **L1 — One engineer** | You | Personal productivity. `/digest-spec` alone saves 30 min per spec. `/qa-check` reduces review-rework cycles. |
| **L2 — One squad** | 3–6 engineers in a squad | Consistent context handoffs. Shared `.pilot/` state during handovers. Squad standups reference digest IDs, not PRD URLs. |
| **L3 — One vertical** | All engineers in a product vertical | Cross-spec conflict detection becomes valuable (related-docs depth-1). PMs start using `/digest-spec` on their own drafts as a sanity check. |
| **L4 — Engineering org** | Everyone | Intent capture becomes default. Spec digestion is a 30-second team-wide step, not a 30-minute per-engineer chore. |

Start at L1. Aim for L2 within 2 weeks. L3 within 8 weeks if the squad signals positive. L4 is a year-long goal.

---

## Two-week pilot — recommended starting shape

**Goal:** validate that the plugin pays for itself within one sprint. If not, the team can drop it cleanly.

### Day 0 — preflight

- [ ] Install Claude Code on your machine if you haven't
- [ ] Confirm Atlassian MCP is configured (`/mcp` lists `claude_ai_Atlassian`)
- [ ] (Optional) Confirm Figma MCP is configured
- [ ] Install the plugin:
  ```
  /plugin marketplace add MD-Sean/WTF
  /plugin install md-sdlc-wf
  ```
- [ ] Run `/plugin list` — confirm `md-sdlc-wf@0.1.0` shows up
- [ ] Pick the next 1–2 PRDs you'd normally have to read top-to-bottom

### Week 1 — solo use, just digest

Run only `/digest-spec` on every PRD you encounter. No `/pilot`, no `/qa-check` yet. Goal: build trust in the digest output before committing to the orchestration.

What to expect:

- First run authenticates Atlassian MCP. May ask permission.
- ≤ 100 line summary should appear within 5–10 seconds for most PRDs.
- Loud warnings if spec is `Draft` or has no AC. These should match your gut.
- Cached digest sits in `.pilot/<spec-id>/digest.json`. Subsequent runs are near-instant.

Stop if: digests are consistently wrong, or you can't authenticate Atlassian within a day. File issue in the repo.

### Week 2 — full pipeline + AC coverage

For one real spec, run `/pilot` end-to-end. Then implement against the produced context packs. Before raising the PR, run `/qa-check`.

What to expect:

- `/pilot` halts at each phase. Take your time reviewing each output. Halt boundaries are intentional — don't speed through them.
- Context packs at `.pilot/<spec-id>/context/G*.md` should feel like a senior engineer's "here's where to look" note.
- AC handoffs go to `senior-frontend-engineer` one group at a time. Review what gets written before approving the next group.
- `/qa-check` will fire after you push tests. Verdict should match what the senior reviewer would catch.

Stop if: pipeline produces low-signal context packs, or the AC verdicts are off. Worth a retro.

### End of week 2 — retro

Five-question retro with yourself (or your squad if multiple ran the pilot):

1. How much time did `/digest-spec` save per PRD? (Aim: ≥15 min)
2. Did the `context-loader` output match what you would have hunted for manually?
3. Did `/qa-check` find at least one gap you would have missed?
4. Did anything block your normal workflow?
5. Would you keep it for another sprint?

If 3 of 5 are yes: commit to L2 (squad-wide pilot). Otherwise: file specific gripes, hold at L1, revisit in a month.

---

## Rolling out to a squad (L2)

Once one engineer is sold, expand to the squad. Don't broadcast — show.

### Setup

- [ ] Pick a squad standup. Run `/digest-spec` live on the squad's current top-priority PRD. Show the output, no commentary.
- [ ] Send a 1-paragraph Slack message to the squad channel:

  > Trying out a Claude Code plugin for spec triage and AC coverage. `/digest-spec <Confluence URL>` gives a 100-line dense summary. `/pilot` runs the full pipeline. `/qa-check` checks AC coverage before PR. Install: `/plugin marketplace add MD-Sean/WTF` then `/plugin install md-sdlc-wf`. Docs: https://sdlc-pipeline-docs.vercel.app

- [ ] Stay available for 1:1 support during the first week.

### What to measure (week 1–4 of squad pilot)

| Metric | Baseline | Target |
|---|---|---|
| Avg time to "understood the spec" | self-report ~30–45 min | ≤ 10 min |
| AC misses caught at code review | self-report ~1–2 per PR | ≤ 0.5 per PR |
| "Where does X live in the repo" pings in squad channel | self-report ~3–5/week | ≥ 50% reduction |

Don't formalize this. Eyeball it. If squad keeps using it after week 4, adoption stuck.

### When to halt squad rollout

- Squad reports the plugin slows them down (after honest week of use)
- MCP outages block more than 10% of pipeline runs
- Cache directory `.pilot/` causes git noise (add to `.gitignore` repo-wide — done automatically by `/pilot` on first run)

---

## Rolling out to a vertical (L3)

After the squad pilot, expand to all engineers in a product vertical.

### Setup

- [ ] Announce in vertical-wide channel
- [ ] Add a 1-paragraph note to the vertical's onboarding doc
- [ ] Designate 1–2 "pipeline champions" per squad — engineers who can answer questions
- [ ] Run a 30-min lunch-and-learn — use the live demo from the [walkthrough](https://sdlc-pipeline-docs.vercel.app)

### Encourage PMs to digest their own drafts

This is when the plugin starts paying back upstream. PMs who run `/digest-spec` on their own in-flight PRDs catch:

- Missing AC matrix
- Inconsistent platform tagging
- No measurement source for KPIs
- Status fields not declared
- Figma links absent on UI specs

Frame it as a quality-of-PRD self-check, not a process imposition.

---

## Rolling out org-wide (L4)

Goal: every engineering team uses `/digest-spec` minimum, with `/pilot` on opt-in basis.

### Setup

- [ ] Add plugin install to the org-wide engineering onboarding checklist
- [ ] Mention in monthly engineering all-hands (release notes style — 30 seconds)
- [ ] Maintain a `#md-sdlc-wf` Slack channel for adoption support
- [ ] Bundle the plugin into the default Claude Code dotfiles repo (if your org has one)

### What L4 looks like in practice

- Spec triage becomes a 30-second shared step, not a 30-minute per-engineer chore.
- New joiners get the same compressed spec view as staff engineers from day one.
- Cross-team specs are discovered automatically via `related_docs` depth-1.
- AC coverage warns surface in `/qa-check`, not in code-review back-and-forth.
- `.pilot/<spec-id>/` directories become a shared shorthand in code-review comments and standups.

---

## Safety hooks

The plugin ships a `PreToolUse` hook that blocks dangerous Bash commands in any Claude Code session running in this repo. It's wired automatically — no configuration needed after install.

### What gets blocked

| Pattern | Reason |
|---|---|
| `rm -rf /`, `rm -rf ~` | Destructive filesystem wipes |
| `git push --force main/master` | Force-push to protected branches |
| `git reset --hard` | Discards uncommitted work |
| `git checkout -- .` | Bulk working-tree discard |
| `git clean -fd` | Deletes untracked files |
| `curl \| /bin/bash`, `wget \| /bin/sh` | Remote code execution via pipe |

### How it works

Hook fires on every `Bash` tool call Claude makes. The command is checked against the deny list before execution. If it matches, Claude Code gets a clear error and is asked to propose a safer alternative.

Heredoc bodies — commit messages, inline scripts — are stripped before matching, so text like "removes destructive filesystem patterns" inside a commit message won't trigger a false positive.

### Files

| File | Purpose |
|---|---|
| `.claude/hooks/block-dangerous.sh` | Hook script. Deny patterns live here. |
| `.claude/settings.json` | Wires the hook to `PreToolUse → Bash`. Ships with the plugin. |

### Extending for your repo

Fork or copy `block-dangerous.sh` into your repo's `.claude/hooks/` and add patterns to `DENY_PATTERNS`. Each entry is an ERE regex matched case-insensitively after heredoc stripping:

```bash
# example: block dropping any database
"drop (table|database|schema)"
```

Your repo's `.claude/settings.json` should wire the hook the same way the plugin does. If you already have `PreToolUse` hooks, add this one alongside — don't replace.

---

## Common objections — and honest responses

| Objection | Response |
|---|---|
| "I already read PRDs fast. I don't need a digest." | The digest isn't only for you. It's for the engineer joining the squad next month who hasn't built your muscle memory. Run `/digest-spec` once. If it tells you nothing new, fine. Cost: 30 seconds. |
| "I don't trust an AI-generated summary." | Don't trust it blindly. The digest preserves the AC table verbatim from the spec — IDs, scenarios, Given/When/Then. It compresses prose around it, but the contractual AC text is the source. Verify by spot-checking the AC table. |
| "It'll break when MCP is down." | `/digest-spec` returns cached digest with a clear warning. `figma-reader` degrades gracefully — pipeline continues without design refs. Engineer is never blocked outright. |
| "We already have a senior-code-reviewer." | `/qa-check` and `senior-code-reviewer` solve different problems. Reviewer judges code *quality* — race conditions, SSR, cleanups. `/qa-check` judges AC *coverage* — does a test exist for each acceptance criterion. Use both. |
| "What if the team I work with doesn't use Claude Code?" | The plugin is engineer-side. Your PMs, designers, and QA don't need to change anything. They write Confluence PRDs and Figma frames as they always have. |
| "What if my PRDs don't have AC matrices?" | The digest will warn loudly with `no_acceptance_criteria`. This is the plugin doing its job — flagging an upstream quality gap. Push back to the PM. |
| "Will my .pilot/ directory bloat the repo?" | `/pilot` auto-adds `.pilot/` to `.gitignore` on first run. Local scratch only. 90-day TTL after spec status = Done. |

---

## How to know it's working

After 2 months of squad-level adoption, you should see:

- **Engineer-side**: PR comments that say "see SPEC-2026-NNN AC-07" instead of "what does this AC mean"
- **Reviewer-side**: code-review feedback shifts toward quality, not coverage
- **PM-side**: PMs start fixing their own PRDs based on `/digest-spec` warnings
- **Standup-side**: people reference `SPEC-2026-NNN` and `G3` (AC group ID) instead of explaining the whole spec verbally

These are leading indicators. Trailing indicators (defect rates, time-to-merge) shift in months, not weeks. Don't gate adoption decisions on trailing metrics — gate on the leading ones above.

---

## When to remove the plugin

Honest exit ramp. Plugin failed if:

- Engineers consistently bypass `/digest-spec` and read PRDs manually anyway (after honest 4-week use)
- `/qa-check` produces too many false positives (engineers learn to ignore the warnings)
- MCP outages exceed 10% of pipeline runs and persist for >2 weeks
- Adoption stalls at L1 for 3+ months despite organic growth attempts

Uninstall is clean:

```
/plugin uninstall md-sdlc-wf
/plugin marketplace remove MD-Sean/WTF
```

`.pilot/` directories remain in repos as cached state. Delete with `rm -rf .pilot/` if you want a fresh slate.

No vendor lock-in. No data migration. You can restart any time.

---

## Feedback + escalation

Internal Mudah team: ping `@kahsing` in Slack or open an issue in the repo. Mention the spec ID, what you ran, and what you expected vs got.

For repeated MCP outages: escalate to your platform team — those are infrastructure concerns, not plugin concerns.
