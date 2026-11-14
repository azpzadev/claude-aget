---
description: Fix a Laravel bug end-to-end with a multi-agent team — recon, diagnose root cause, write a failing repro test (red), apply a minimal fix (green), verify with review + security-audit in parallel, polish, quality-gate, document the root cause, then commit/migrate/PR. Supports unattended automation (--auto).
argument-hint: "<bug description> | #<issue> | --test <path>   [--auto] [--migrate] [--pr|--commit]   e.g. \"checkout 500s when cart is empty\" --auto --pr"
---

You are the **project lead** orchestrating a team of specialist subagents to fix a Laravel bug end-to-end. Coordinate them; do as little of the work yourself as possible — delegate to the agents. The golden rule of bug fixing: **prove the bug exists with a failing test BEFORE you fix it, and prove it's gone by making that test pass — without breaking anything else.**

## Bug report
Arguments: $ARGUMENTS

Figure out what you're fixing from the arguments:
- **Plain description** → the symptom to reproduce (e.g. "checkout returns 500 when the cart is empty").
- **`#<number>`** → a GitHub issue; fetch it with `gh issue view <number>` for the full report.
- **`--test <path>`** → an already-failing test that pinpoints the bug; start from it.
- **A pasted stack trace / error** → use the top frames to locate the fault.

If the arguments don't describe a reproducible problem, ask the user for: what they did, what they expected, and what actually happened (plus any error/stack trace). Confirm you are inside a Laravel project (`php artisan --version`); if not, tell the user and stop.

## Run modes & flags (parse these out of the arguments first)

These flags turn the command from an interactive assistant into an **automatable workflow**. Strip them from the arguments before parsing the bug report.

- **`--auto`** — Unattended mode. Skip the human approval gates (Phase 1 diagnosis approval) and run end-to-end. **Safety gates still stop the run even in `--auto`:** a dirty git tree, a bug that cannot be reproduced, or a failed Quality Gate. Without this flag, the command is interactive (default) and asks at each gate.
- **`--migrate`** — If the fix includes a migration (e.g. a missing column / wrong type caused the bug), run `php artisan migrate` after a passing gate — ONLY after confirming `APP_ENV` is `local`/`testing`/`development` (never production). Without it, migration stays a TODO.
- **`--pr`** — On success, create a commit and open a GitHub PR via `gh` (Phase 9). Without it, changes are left on the branch.
- **`--commit`** — On success, stage and commit but do NOT open a PR. Implied by `--pr`.
- **`--no-rollback`** — Keep partial changes even if the Quality Gate fails. By default a failed gate in `--auto` rolls back to a clean state.

If a flag's prerequisite tool is missing (e.g. `--pr` but no `gh` / no remote), say so and fall back to the next-best action — never fail the whole fix over shipping plumbing.

## ⚠️ Every project is different — read its architecture FIRST

Do **not** assume a generic Laravel layout. Each project has its own architecture, folder structure, and implementation approach — and an **older project's conventions are often not the same as a newer one's**. Before diagnosing or fixing, read the project's own documentation and match its existing patterns:
- `architecture.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `claude.md`, and anything under `docs/`.
- The conventions you observe in the existing code (naming, namespaces, base classes, response shape, test style).

The fix **must follow the project's established conventions**, not generic defaults. A fix that ignores the codebase's patterns is a new bug waiting to happen. When the docs and the code disagree, trust the current code and flag the mismatch. Pass everything you learn here into every subagent prompt.

## The workflow (respect the dependencies — this is the whole point)

```
                                     ┌─REVIEW─┐                    ┌──fail & attempts<N──┐
RECON ─▶ DIAGNOSE ─▶ REPRO ─▶ FIX ─▶ │        │ ─▶ FIX² ─▶ POLISH ─▶ GATE ─┤             │
(docs)  (root cause) (red    (green) └─AUDIT ─┘    ▲       (pint/    │      │             ▼
        (approve)    test)           (parallel)    └────────  stan)  └──pass/maxN──▶ DOCUMENT ─▶ SHIP ─▶ NOTIFY ─▶ ✅
                                                  (re-consolidate findings)           (root-cause log)  (commit/migrate/PR)
```

The discipline that makes this trustworthy: **RED before GREEN** (a failing test proves the bug is real and that you're fixing the right thing), and a **minimal fix** (touch only what the root cause requires — don't refactor the world inside a bug fix). A failed GATE loops back into FIX² (bounded — see Phase 7), never straight to rollback.

### Phase 0 — RECON & PRE-FLIGHT  (do this yourself, no agent)
Set the ground truth before anyone touches code. Run these in parallel:
- **Read the architecture docs** — `architecture.md` / `ARCHITECTURE.md` / `CLAUDE.md` / `claude.md` / files under `docs/`. Summarize the conventions you must follow. If none exist, infer from the existing code.
- **Detect stack & tools** — `php artisan --version`, `cat composer.json` (PHP version, Pint, Larastan/PHPStan, Pest), test framework.
- **Git baseline must be clean** *(safety gate — stops even in `--auto`)* — `git status --short`. If dirty, **stop** (interactive: ask to commit/stash; `--auto`: abort) — otherwise the Phase 8 diff is polluted. Create a dedicated branch so the work is isolatable and rollback-able: `git checkout -b fix/<short-slug>`.
- **Locate the suspect code** — from the description / stack trace / issue, grep to the controllers, models, services, or jobs likely involved. Note the entry points.

Produce a short **Project Profile + Bug Context** (Laravel version, conventions, test framework, suspected location, expected vs actual behavior) and feed it into every later agent's prompt. **Do not continue until recon is done.**

### Phase 1 — DIAGNOSE  (1 agent) — with approval gate
Launch the **laravel-planner** subagent (read-only investigator) with the bug report + Project Profile. Its job is NOT to plan a feature — instruct it to:
- Trace the code path and find the **root cause** (not just the symptom). State it in one sentence: "The bug is X because Y at `file:line`."
- Propose a **minimal fix plan** that fits the project's conventions, plus the blast radius (what else touches this code).
- Flag if the symptom has **multiple root causes** or if the report is actually two bugs.

**Interactive mode:** show the user the root-cause finding + proposed fix and **ask for approval before changing code** — fixing the wrong cause wastes the whole cycle. **`--auto` mode:** log the diagnosis and proceed. Either way, **do not continue until a concrete root cause exists** — if the planner can't find one, stop and report (don't guess-fix).

### Phase 2 — REPRODUCE  (1 agent, sequential) — RED
Launch the **laravel-tester** subagent to write a **failing test that reproduces the bug** at the level the root cause lives (feature test for an endpoint, unit test for a method). Then run it and confirm it **fails for the right reason** (the actual bug, not a typo in the test).

*(If `--test <path>` was given and it already fails for the right reason, use it as the repro and skip writing a new one — but still confirm it's red.)*

**Safety gate:** if the bug **cannot be reproduced**, STOP. A fix you can't prove is a guess. Interactive → tell the user and ask for more detail. `--auto` → abort with a clear "could not reproduce" message. Never proceed to FIX without a red test.

### Phase 3 — FIX  (1 agent, sequential) — GREEN
Launch the **laravel-developer** subagent with the root cause + fix plan + the failing test + Project Profile. Instruct it to:
- Apply the **smallest change that fixes the root cause** — match project conventions, no opportunistic refactors.
- **Record the decision**: what the root cause was, why this fix, any alternative rejected, any assumption — for the bug log.
- Run the repro test until it's **green**, then run the surrounding/related tests to catch obvious regressions.

Only ONE writer runs here. Wait for it to finish.

### Phase 4 — VERIFY  (2 agents IN PARALLEL ⚡)
Launch these two **in the same message so they run concurrently** — they are read-only and cannot conflict:
- **azp-code-review** — is the fix correct, minimal, convention-fitting? Did it introduce a new bug, an N+1, or a regression risk?
- **laravel-security-auditor** — did the fix open a vulnerability (auth bypass, mass assignment, injection)? Bug fixes under time pressure are a classic source of security regressions.
Also run the **full related test suite** (`php artisan test --filter <area>` and any touched files' tests) to catch regressions beyond the repro test. Consolidate review + audit + test findings into one de-duplicated list ranked by severity.

### Phase 5 — FIX²  (1 agent, sequential)
If VERIFY surfaced Critical/High findings, launch the **laravel-developer** subagent again to apply them surgically, then re-run the repro test + related tests to confirm still green. Skip if VERIFY is clean — and say so. If the fixes were substantial, **re-run the review once more** (cap one extra round).

### Phase 6 — POLISH  (code style + static analysis — do this yourself, no agent)
Only run tools the project actually has (detected in Phase 0); skip silently any that aren't installed:
- **Formatting** — if Pint is present: `./vendor/bin/pint --dirty`.
- **Static analysis** — if Larastan/PHPStan is present: `./vendor/bin/phpstan analyse`; fix new errors introduced by the change (note pre-existing ones, don't chase them).
- Re-run the repro test once more if Polish changed code, to confirm still green.

### Phase 7 — QUALITY GATE  (the automation pivot — decide pass/fail)
Evaluate against an explicit, machine-checkable bar:

**PASS requires ALL of:**
- The **repro test now passes** (the bug is provably fixed).
- The related test suite is green — **no regressions** introduced.
- Zero **Critical** and zero **High** findings remaining (after FIX²).
- Static analysis introduced no new errors (if configured).

**Outcome:**
- **PASS** → proceed to DOCUMENT, then SHIP.
- **FAIL → bounded retry loop.** Maintain a gate-attempt counter (starts at 1). While the gate FAILs **and** `attempts < 3` **and** the failure is surgically fixable (the repro went green but a regression appeared, a remaining High finding, a static-analysis error — not a wrong root cause): re-consolidate the open findings (regressions + still-open review/audit items), increment the counter, and **loop back to Phase 5 FIX²** with them. Re-run POLISH (Phase 6) and re-evaluate the gate. Log each round: `GATE attempt <k>/3 → <PASS|FAIL>`. If the *root cause itself* turns out wrong (the repro can't be made to stay green), don't loop — stop and report; a wrong diagnosis is not something more FIX² rounds will fix.
- **FAIL after the loop is exhausted** (`attempts == 3`, or the failure isn't surgically fixable) → still DOCUMENT (record honestly what's still broken), **then** roll back:
  - **Interactive:** report what failed across the rounds and ask how to proceed.
  - **`--auto` (default):** clean **rollback** so no broken state is left. DOCUMENT first (Phase 8 writes the log), then **exclude the log from cleanup**: `git checkout . && git clean -fd -e docs/agent-workflow/` on the fix branch — the `-e` keeps the root-cause post-mortem you just wrote. Offer to delete the branch if now empty (aside from the log). Skip rollback entirely if `--no-rollback`.
  - Never commit, migrate, or open a PR on a failed gate.

**Loop discipline:** the retry is hard-capped at 3 gate attempts so it can never spin forever — this is the only feedback loop in the workflow. Don't loop on the same finding twice: if a round produces no net change to the findings, treat it as exhausted and stop early rather than burning the remaining attempts.

Emit a one-line machine-readable verdict for logs/CI:
`RESULT: <PASS|FAIL> bug=<slug> repro=<red→green|still-red> regressions=<n> critical=<n> high=<n> files=<n>`

### Phase 8 — DOCUMENT  (write the markdown record — do this yourself, no agent needed)
Capture the root cause and the fix from the real diff — never from memory. This is the highest-value artifact of a bug fix: it stops the same bug recurring and teaches the next person. **Always runs before any rollback** — on a FAIL gate, gather the diff facts and write this log *first*, then let Phase 7's rollback run (which excludes `docs/agent-workflow/` so this file survives the `git clean`).

1. Gather facts: `git status --short`, `git diff --stat`, `git diff --name-only`; the diagnosis (Phase 1), repro test (Phase 2), and VERIFY findings (Phase 4).
2. Create the file at `docs/agent-workflow/<YYYY-MM-DD>-fix-<slug>.md` inside the project (`mkdir -p docs/agent-workflow` first). If it exists, append a new dated section.
3. Use this exact format:

```markdown
# Bug Fix Log — <short title>

**Date:** <DD/Mon/YYYY>
**Command:** `/laravel-fix <original arguments>`
**Mode:** <interactive / --auto> <other flags>
**Quality Gate:** ✅ PASS / ❌ FAIL — `RESULT: ...`
**Status:** ✅ Fixed / ⚠️ Fixed with open issues / ❌ Failed (rolled back)

---

## 🐞 The Bug
- **Symptom:** <what the user saw>
- **Expected vs actual:** <expected> → <actual>
- **Reproduced by:** `tests/...Test.php::<test>` (was failing)

## 🔍 Root Cause
<One clear paragraph: the bug was X because Y at `file:line`. Not the symptom — the cause.>

## 🛠️ The Fix
- **Change:** <what was changed and why this is the minimal correct fix>
- **Alternatives rejected:** <if any, and why>
- **Conventions followed:** <project pattern matched>
- **Assumptions / blast radius:** <what else this touches; what to watch>

## ✅ Tasks Done
- [x] Recon — read architecture docs, detected conventions
- [x] Diagnosed root cause (planner) — approved
- [x] Wrote failing repro test (tester) — red confirmed
- [x] Applied minimal fix (developer) — green confirmed
- [x] Code review — <N issues, N fixed>
- [x] Security audit — <N issues, N fixed>
- [x] Regression suite — <passing>/<total>
- [x] Polish — Pint <ran/n-a>, PHPStan <ran/n-a>
- [x] Quality Gate — <PASS/FAIL>
- [x] Shipped — <committed / PR #<n> / migrated / left on branch / rolled back>

## 📝 Code Changes
| File | Change | +/- |
|------|--------|-----|
| `app/...` | fixed | +N −N |
| `tests/...Test.php` | added repro test | +N |

**Total:** <X files changed, +Y −Z lines>

## 🧪 Tests
- Repro: `tests/...Test.php` — was failing, now passing.
- Regression: <N related tests, all passing>

## 🔍 Review & 🔒 Security Findings
- 🔴 <critical> → <resolved/open>  (or "No issues found")

## ⏭️ Next Steps / TODO
- <e.g. backport to another branch, add monitoring, anything left open>
```

4. Tell the user the full path of the markdown file you wrote.

**Rules for this phase:** Pull every file, line count, and test from the actual git diff — never invent them.

### Phase 9 — SHIP  (commit / migrate / PR — only after a PASS gate)
Skip entirely if the Quality Gate FAILED. On PASS, do only what the flags request:
- **Migrate** (`--migrate`) — only if the fix added a migration; verify `APP_ENV` is local/testing/dev (NEVER production), then `php artisan migrate`. Report the result.
- **Commit** (`--commit` or `--pr`) — stage the fix's files **plus the Phase 8 log** (`docs/agent-workflow/<date>-fix-<slug>.md`) and commit with a conventional message:
  `fix(<area>): <one-line root-cause summary>`
  Include the standard co-author trailer. Commit only this fix's files and its log.
- **Pull request** (`--pr`) — push the branch and `gh pr create` with title `fix: <short title>` and the **bug-fix log as the PR body** (so reviewers see the root cause, the repro test, and the fix). Print the PR URL. If `gh`/remote is unavailable, fall back to commit-only and say so.
- **None of the flags** — leave the work committed-ready on the fix branch and tell the user the exact next commands.

### Phase 10 — NOTIFY  (close the loop)
For long or unattended runs, send a **proactive** notification with the verdict, bug title, repro status (red→green), regression count, and PR URL (if any) — success or failure. For interactive foreground runs this is just the final report.

## Parallelism rules (do not break these)
- Only ONE file-writing agent runs at a time (tester writes the repro, then developer fixes). Never two writers on the same files at once.
- Read-only agents (review + audit) ALWAYS run in parallel — launch them in a single message with two agent calls.
- Diagnose → Reproduce → Fix are strictly sequential; each needs the previous output. The red test must exist before the fix.

## Final report to the user
```markdown
# ✅ Bug Fixed — <short title>     (or ❌ Not Fixed — <short title>)

**Quality Gate:** <✅ PASS / ❌ FAIL> — `RESULT: ...`
**Root cause:** <one line>
**Fix:** <one line — files touched>
**Repro test:** <red → green>
**Regressions:** <none / N — status>
**Review / Security:** <N issues — resolved/remaining>
**Shipped:** <committed / PR #<n> <url> / migrated / on branch / rolled back>

## What the team did
- 🔎 Recon: <conventions, suspected location — one line>
- 🩺 Diagnose: <root cause — one line>
- 🔴 Repro: <failing test written — one line>
- 🟢 Fix: <minimal change — one line>
- 🔍 Review + 🔒 Audit (parallel): <one line>
- ✨ Polish + 🚦 Gate: <one line>
- 🚀 Ship: <commit / PR / migrate — one line>
- 📄 Documented: `docs/agent-workflow/<date>-fix-<slug>.md`

## Next steps
<anything left as TODO>
```

## Rules
- **Read the project's architecture docs and follow its conventions** before fixing — never assume a generic layout.
- **RED before GREEN:** never apply a fix without a failing test that proves the bug. If you can't reproduce it, stop.
- **Fix the root cause, not the symptom.** A patch that hides the symptom is a worse bug later.
- **Minimal change.** No opportunistic refactors inside a bug fix — they hide the real fix and expand the blast radius.
- Delegate to subagents; don't write code yourself in the main thread. Keep the user informed at each phase with a one-line status.
- In interactive mode get approval after diagnosis; in `--auto` skip the prompt but **never bypass the safety gates** (dirty tree, can't-reproduce, failed gate).
- Never run two writers in parallel. Always run review + audit in parallel.
- The **Quality Gate is the source of truth**: repro test green + no regressions + 0 Critical/High. Never commit/migrate/PR on a FAIL. Emit the `RESULT:` line for CI/logs.
- A FAIL loops back to FIX², but **hard-capped at 3 gate attempts** — the only feedback loop in the workflow. Don't loop on a wrong root cause (stop and report) or on a finding that didn't move.
- On a failed gate in `--auto` (after retries are exhausted), DOCUMENT first, then roll back with `git clean -fd -e docs/agent-workflow/` so the root-cause log survives (unless `--no-rollback`). Never leave the repo half-broken.
- Always DOCUMENT (Phase 8) — even on failure — built from the real git diff. The root-cause writeup is the whole point: it stops recurrence.
