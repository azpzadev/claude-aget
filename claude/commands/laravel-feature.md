---
description: Build a complete Laravel feature (CRUD/API/module) — and its UI when the project has a frontend — using a parallel multi-agent team: recon, plan, develop API, test, build UI (ui-developer, 1:1 from reference designs), review + security-audit in parallel, fix, polish, quality-gate, document, then commit/migrate/PR. Supports unattended automation (--auto) and batch builds.
argument-hint: "<Model> field:type ... | <F-xx backlog id>  [--auto] [--migrate] [--pr|--commit] [--no-ui|--ui-only]   e.g. F-04  or  Product name:string price:decimal --auto --pr"
---

You are the **project lead** orchestrating a team of specialist subagents to build a Laravel feature end-to-end. Coordinate them; do as little of the work yourself as possible — delegate to the agents.

## Feature request
Arguments: $ARGUMENTS

Parse the model name and the `field:type` list. If no arguments were given, ask the user for the model name and fields before starting.

**Backlog id instead of fields:** if the argument is a feature id like `F-04` and the project (or its product root) has a backlog doc (e.g. `docs/ui-port.md`), read that row. It gives the screen, the reference design (file + line range), the frontend target and its dependencies. The planner then derives the model/fields from the reference design + the spec docs. Check that the row's "Needs" features are done; if not, tell the user which one to build first and stop (interactive) or abort (`--auto`).

**Where is Laravel?** Confirm you are inside a Laravel project (`php artisan --version`). In a multi-repo product root (a folder with `PRODUCT.md` and `<product>-api` / `<product>-web` sub-repos), run the Laravel steps inside the `-api` repo and the UI steps inside the `-web` repo; each repo gets its own branch, diff and commit. If no Laravel project is found, tell the user and stop.

## Run modes & flags (parse these out of the arguments first)

These flags turn the command from an interactive assistant into an **automatable workflow**. Strip them from the arguments before parsing model/fields.

- **`--auto`** — Unattended mode. Skip the human approval gates (Phase 1 plan approval, API/web question) and run end-to-end. **Safety gates still stop the run even in `--auto`:** a dirty git tree, an existing model conflict, or a failed Quality Gate. Without this flag, the command is interactive (default) and asks at each gate as before.
- **`--migrate`** — After a passing Quality Gate, run `php artisan migrate` — but ONLY after confirming `APP_ENV` is `local`/`testing`/`development` (never on production). Without it, migration stays a TODO.
- **`--pr`** — On success, create a commit and open a GitHub PR via `gh` (Phase 9). Without it, changes are left in the working tree / branch for the user to commit.
- **`--commit`** — On success, stage and commit (but do NOT open a PR). Implied by `--pr`.
- **`--no-rollback`** — Keep partial changes even if the Quality Gate fails. By default a failed gate in `--auto` offers/performs a clean rollback.
- **`--no-ui`** — Build the API only and skip Phase 3b (UI), even when the project has a frontend.
- **`--ui-only`** — The API already exists; skip Phases 1–3 for the backend. Plan only the UI (the planner reads the existing routes/Resources) and run 3b → VERIFY → … as usual.

**Batch mode:** if the arguments contain multiple models separated by `;` (e.g. `Product name:string ; Order total:decimal user_id:foreignId`), run the FULL workflow for each model **sequentially, one complete cycle at a time** (never build two in parallel — they may touch shared files like routes). Produce one feature log per model and one combined final report. In batch mode, prefer `--auto` so it doesn't block between models.

If a flag is present but the prerequisite tool is missing (e.g. `--pr` but no `gh`, or `--pr` outside a repo with a remote), say so and fall back to the next-best action (commit only, or leave in working tree) — never fail the whole feature over shipping plumbing.

## ⚠️ Every project is different — read its architecture FIRST

Do **not** assume a generic Laravel layout. Each project has its own architecture, folder structure, and implementation approach — and an **older project's conventions are often not the same as a newer one's** (e.g. fat-controller vs Service/Action, `JsonResource` vs custom responders, repository layer vs plain Eloquent, API vs web+Blade, Pest vs PHPUnit).

Before any planning or coding, **read the project's own documentation and match its existing patterns**:
- `architecture.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `claude.md`, and anything under `docs/`.
- The conventions you observe in the existing code (naming, namespaces, base classes, response shape, test style).

The planner and developer **must follow the project's established conventions**, not their own defaults. When the docs and the code disagree, trust the current code and flag the mismatch to the user. Pass everything you learn here into every subagent prompt so the whole team builds in the project's style.

## The workflow (respect the dependencies — this is the whole point)

```
                                             ┌─REVIEW─┐                  ┌──fail & attempts<N──┐
RECON ─▶ PLAN ─▶ BUILD ─▶ TEST ─▶ UI BUILD ─▶ │        │ ─▶ FIX ─▶ POLISH ─▶ GATE ─┤             │
(docs)  (approve) (api)   (api)   (ui-dev,   └─AUDIT ─┘    ▲   (pint+stan  │             ▼
                                   if UI)    (parallel)    │    +lint/tsc)  └─pass/maxN─▶ DOCUMENT ─▶ SHIP ─▶ ✅
                                                           └── (laravel-developer for API findings,
                                                                ui-developer for UI findings)
```

The **GATE** is the automation pivot: pass → document + ship; fail → loop back to FIX (bounded, see Phase 7) and, once retries are exhausted, document the open issues and (in `--auto`) roll back. Always DOCUMENT, even on failure.

### Phase 0 — RECON & PRE-FLIGHT  (do this yourself, no agent)
Set the ground truth before anyone writes code. Run these in parallel:
- **Read the architecture docs** — `architecture.md` / `ARCHITECTURE.md` / `CLAUDE.md` / `claude.md` / files under `docs/`. Summarize the conventions you must follow (structure, layers, response style, test framework). If none exist, say so and infer conventions from the existing code.
- **Detect stack & conventions** — `php artisan --version` (Laravel version), `cat composer.json` (PHP version, key packages: Pint, Larastan/PHPStan, Pest), `ls app/` (Service/Action/Repository layers? API or web?).
- **Git baseline must be clean** *(safety gate — stops even in `--auto`)* — run `git status --short`. If the working tree is dirty, **stop** (interactive: ask to commit/stash; `--auto`: abort with a clear message) — otherwise the Phase 8 diff will be polluted with unrelated changes. Always create a dedicated branch so the work is isolatable and rollback-able: `git checkout -b feature/<model>`.
- **Model conflict check** *(safety gate — stops even in `--auto`)* — does the model / migration / table already exist? `ls app/Models/<Model>.php`, grep migrations for the table. If it exists: interactive → ask extend or stop; `--auto` → abort (don't silently overwrite someone's model).
- **API or Web?** — if the project clearly uses one (or the docs say so), follow that. If ambiguous: interactive → ask; `--auto` → default to whatever the existing code uses most, and note the assumption in the log.
- **Frontend & UI reference** — is there a UI to build? Look for a sibling `<product>-web` repo (Nuxt/Vue/React: `package.json`), a Blade/Inertia frontend inside the Laravel app, and UI reference material (`docs/ui-port.md`, `docs/reference/prototypes/`, `reference/UI/`). Read the frontend repo's `CLAUDE.md` and its `package.json` scripts (lint / typecheck / test / test:e2e). The frontend repo must also have a clean git tree *(safety gate)*. UI is **on** when a frontend exists and `--no-ui` was not passed.

Produce a short **Project Profile** (Laravel version, conventions, API/web, test framework, notable packages, **frontend stack + its check commands + UI reference rules**, or "no UI") and feed it into every later agent's prompt. **Do not continue until recon is done.**

### Phase 1 — PLAN  (1 agent) — with approval gate
Launch the **laravel-planner** subagent with the model + fields **and the Project Profile from Phase 0**, instructing it to follow the project's existing conventions (not generic defaults). It returns a build plan (schema, file checklist, security requirements). When UI is on, also tell it to read the reference design for the screen and include a **UI section** in the plan: which screens/components, which API endpoints and fields each one needs (so the API is designed for the screen), and the reference file + line range to port.

**Interactive mode:** show the user a concise summary of the plan (schema + files + key decisions) and **ask the user to approve before building** — a wrong schema caught here saves the whole BUILD/TEST/FIX cycle. Do not proceed to Phase 2 until the user approves (or adjusts). **`--auto` mode:** skip the approval prompt, log the plan summary, and proceed. Either way, **do not continue until the plan exists** — every later agent depends on it.

### Phase 2 — BUILD  (1 agent, sequential)
Launch the **laravel-developer** subagent with the full plan **and the Project Profile**. It creates the migration, model, FormRequests, controller, resource, routes, factory — **matching the project's existing conventions**, not generic defaults. Instruct it to **record any notable implementation decisions** (why a pattern was chosen, deviations from the plan, assumptions, trade-offs) and return them — these go into the feature log so future team members understand the choices and the codebase stays consistent. Wait for it to finish — nothing can be tested or reviewed before the code exists. Only ONE writer runs here (no parallel writers on the same files).

### Phase 3 — TEST  (1 agent, sequential)
Launch the **laravel-tester** subagent. It writes + runs feature/unit tests. It may report app bugs as findings — collect them for the FIX phase.

### Phase 3b — UI BUILD  (1 agent, sequential — only when UI is on)
Launch the **ui-developer** subagent in the frontend repo with: the plan's UI section, the API that now exists (routes from `php artisan route:list --path=<prefix>`, the Resource + FormRequest files, error codes, OpenAPI if present), the Project Profile, and the UI reference rules (e.g. "port 1:1 from `<file>` lines A–B; allowed differences only per `docs/ui-port.md`"). It builds the screens, wires them to the API, writes the frontend tests, runs the frontend checks and returns: files changed, endpoints used, **differences from the reference**, and missing API capabilities. Missing API capabilities become findings for the laravel-developer in FIX. It runs **after** TEST so it builds against a tested API; it is the only writer while it runs.

### Phase 4 — VERIFY  (2 agents IN PARALLEL ⚡)
Launch these two **in the same message so they run concurrently** — they are read-only and cannot conflict:
- **azp-code-review** — quality, bugs, conventions, performance.
- **laravel-security-auditor** — vulnerabilities.

When UI is on, give both agents the frontend diff too (review: fidelity to the reference, component reuse, i18n completeness, types, a11y; audit: no tokens or secrets in client code, `v-html` / XSS, data leaking to the wrong audience, CSRF on mutations). Pass both agents the **known-failing tests from Phase 3** (if any) so they don't re-report issues the tests already cover — tell them "tests may currently be red; here are the known failures: <list> — focus on issues *not* already captured by these." Collect both reports plus any tester findings into one consolidated, de-duplicated list, ranked by severity.

### Phase 5 — FIX  (1 agent, sequential)
If there are Critical/High findings, launch the **laravel-developer** subagent again with the consolidated **backend** findings to apply fixes surgically; then (never at the same time) the **ui-developer** with the **frontend** findings. Then re-run `php artisan test --filter <Model>` to confirm green. Skip this phase if review + audit + tests are all clean — and say so.

If the fixes were substantial (touched logic, not just style), **re-run the review one more time** on the changed files to confirm no new issues were introduced — cap this at one extra round so it doesn't loop forever.

### Phase 6 — POLISH  (code style + static analysis — do this yourself, no agent)
Only run the tools the project actually has (you detected these in Phase 0). Skip silently any that aren't installed:
- **Formatting** — if Pint is present: `./vendor/bin/pint --dirty` (formats only changed files).
- **Static analysis** — if Larastan/PHPStan is present: `./vendor/bin/phpstan analyse` and fix any new errors introduced by this feature (don't chase pre-existing ones — note them instead).
- **Frontend** (UI on) — run the frontend repo's own scripts: lint (with `lint:fix`), typecheck, unit tests; e2e when a dev server/API is reachable (otherwise note "e2e skipped").
- Re-run `php artisan test --filter <Model>` once more if Polish changed any code, to confirm still green.

### Phase 7 — QUALITY GATE  (the automation pivot — decide pass/fail)
Evaluate against an explicit, machine-checkable bar so automation has a clear verdict:

**PASS requires ALL of:**
- All tests green (`php artisan test --filter <Model>` exits 0).
- Zero **Critical** and zero **High** findings remaining (after FIX).
- Static analysis introduced no new errors (if PHPStan/Larastan is configured).
- UI on: frontend lint + typecheck + unit tests green, and no unexplained differences from the reference design.

**Outcome:**
- **PASS** → proceed to DOCUMENT, then SHIP.
- **FAIL → bounded retry loop.** Maintain a gate-attempt counter (starts at 1). While the gate FAILs **and** `attempts < 3` **and** the remaining findings look fixable (a test assertion, a missing guard, a validation rule — not an architectural dead end): re-consolidate the open findings (gate failures + any still-open review/audit items), increment the counter, and **loop back to Phase 5 FIX** with them. Re-run POLISH (Phase 6) and re-evaluate the gate. Log each round: `GATE attempt <k>/3 → <PASS|FAIL>`.
- **FAIL after the loop is exhausted** (`attempts == 3`, or the failure is not surgically fixable) → still DOCUMENT (record the open issues honestly), **then** roll back:
  - **Interactive:** report what failed across the rounds and ask the user how to proceed.
  - **`--auto` (default):** perform a clean **rollback** so no broken state is left. DOCUMENT first (Phase 8 writes the log), then **exclude the log from cleanup**: `git checkout . && git clean -fd -e docs/agent-workflow/` on the feature branch — the `-e` keeps the failure post-mortem you just wrote. If a branch was created and is now empty (aside from the log), offer to delete it. Skip rollback entirely if `--no-rollback` was passed (leave changes for inspection).
  - Never commit, migrate, or open a PR on a failed gate.

**Loop discipline:** the retry is hard-capped at 3 gate attempts so it can never spin forever — this is the only feedback loop in the workflow. Don't loop on the same finding twice: if a round produces no net change to the findings (the fixer couldn't move it), treat it as exhausted and stop early rather than burning the remaining attempts.

Emit a one-line machine-readable verdict for logs/CI, e.g.:
`RESULT: <PASS|FAIL> model=<Model> tests=<pass>/<total> ui_tests=<pass>/<total|n-a> critical=<n> high=<n> files=<n>`

### Phase 8 — DOCUMENT  (write the markdown record — do this yourself, no agent needed)
Capture exactly what the team did and what code changed, from the real diff — never from memory. **Always runs before any rollback** — on a FAIL gate, gather the diff facts and write this log *first*, then let Phase 7's rollback run (which excludes `docs/agent-workflow/` so this file survives the `git clean`).

1. Gather the facts:
   - `git status --short` and `git diff --stat` — files added/changed and line counts.
   - `git diff --name-only` — the file list.
   - The plan (Phase 1), test result (Phase 3), and review/audit findings (Phase 4) you already have.
2. Create the file at `docs/agent-workflow/<YYYY-MM-DD>-<Model>.md` inside the project
   (run `mkdir -p docs/agent-workflow` first). If the file exists, append a new dated section instead of overwriting.
3. Use this exact format:

```markdown
# Feature Log — <Model>

**Date:** <DD/Mon/YYYY>
**Command:** `/laravel-feature <original arguments>`
**Mode:** <interactive / --auto> <other flags>
**Quality Gate:** ✅ PASS / ❌ FAIL — `RESULT: <PASS|FAIL> model=<Model> tests=<p>/<t> critical=<n> high=<n>`
**Status:** ✅ Done / ⚠️ Done with open issues / ❌ Failed (rolled back)

---

## ✅ Tasks Done
- [x] Recon — read architecture docs, detected conventions (Laravel <ver>, <API/web>, <test fw>)
- [x] Planned schema & files (planner) — approved by user
- [x] Built migration, model, requests, controller, routes, factory (developer)
- [x] Wrote & ran tests — <passing>/<total> (tester)
- [x] Built UI — <screens> ported from <reference> (ui-developer) — frontend checks <pass/fail> (or "n/a — no UI")
- [x] Code review — <N issues, N fixed>
- [x] Security audit — <N issues, N fixed>
- [x] Fixes applied (developer)
- [x] Polish — Pint <ran/n-a>, PHPStan <ran/n-a>
- [x] Quality Gate — <PASS/FAIL>
- [x] Shipped — <committed / PR #<n> / migrated / left in working tree>

## 🏛️ Architecture & Decisions
Capture the choices a future teammate would need to understand this feature and keep the codebase consistent:
- **Conventions followed:** <e.g. Service/Action layer, JsonResource responses, Pest tests — what project pattern this matched>
- **Key decisions:** <why this pattern; any deviation from the plan and why>
- **Assumptions / trade-offs:** <anything non-obvious the developer assumed>
- **Mismatches found:** <docs vs code disagreements, flagged>

## 📝 Code Changes
| File | Change | +/- |
|------|--------|-----|
| `database/migrations/xxxx_create_<table>.php` | created | +NN |
| `app/Models/<Model>.php` | created | +NN |
| `app/Http/Controllers/<Model>Controller.php` | created | +NN |
| ... | | |

**Total:** <X files changed, +Y −Z lines>

## 🔀 Routes Added
- `GET /api/<plural>` — index
- `POST /api/<plural>` — store
- ... (the real registered routes)

## 🧪 Tests
- `tests/Feature/<Model>Test.php` — <N tests, all passing/failing>

## 🔍 Review & 🔒 Security Findings
- 🔴 <critical> → <resolved/open>
- 🟠 <high> → <resolved/open>
- (or "No issues found")

## ⏭️ Next Steps / TODO
- <e.g. run `php artisan migrate`, add UI, anything left open>
```

4. Tell the user the full path of the markdown file you wrote.

**Rules for this phase:** Pull every file, line count, and route from the actual git diff / `php artisan route:list` — never invent them. Keep the table accurate to what really changed.

### Phase 9 — SHIP  (commit / migrate / PR — only after a PASS gate)
Skip this phase entirely if the Quality Gate FAILED. On PASS, do only what the flags request:

- **Migrate** (`--migrate`) — verify `php artisan env` / `APP_ENV` is `local`/`testing`/`development` (NEVER production), then `php artisan migrate`. Report the result. Without the flag, leave it as a TODO in the log.
- **Commit** (`--commit` or `--pr`) — stage the feature's files **plus the Phase 8 log** (`docs/agent-workflow/<date>-<Model>.md`) and commit with a conventional message:
  `feat(<model>): add <Model> CRUD — migration, model, requests, controller, tests`
  Include the standard co-author trailer. Commit only this feature's files and its log, not unrelated noise.
- **Pull request** (`--pr`) — push the branch and `gh pr create` with a title `feat: <Model> CRUD` and the **feature log contents as the PR body** (so reviewers see the plan, decisions, tests, and findings). Print the PR URL. If `gh` is unavailable or there's no remote, fall back to commit-only and tell the user.
- **None of the flags** — leave the work committed-ready in the working tree / feature branch and tell the user the exact next commands to run.

### Phase 10 — NOTIFY  (close the loop)
Long or unattended runs should announce their result so the user doesn't have to watch:
- Send a **proactive** notification with the final verdict, model name, test count, and PR URL (if any) — success or failure. For interactive foreground runs this is just the final report; for `--auto`/scheduled/background runs, make it a push so it reaches the user.

## Parallelism rules (do not break these)
- Only ONE file-writing agent runs at a time (developer, then tester, then ui-developer). Never two writers at once, even across repos.
- Read-only agents (review + audit) ALWAYS run in parallel — launch them in a single message with two agent calls.
- Plan → Build → Test are strictly sequential; each needs the previous output.

## Final report to the user
```markdown
# ✅ Feature Built — <Model>     (or ❌ Failed — <Model>)

**Quality Gate:** <✅ PASS / ❌ FAIL> — `RESULT: ...`
**Files created:** <count> — <key files>
**Routes:** <list>
**Tests:** <passing>/<total>
**Review:** <N issues — resolved/remaining>
**Security:** <N issues — resolved/remaining>
**Shipped:** <committed / PR #<n> <url> / migrated / left in working tree / rolled back>

## What the team did
- 🔎 Recon: <Laravel ver, conventions, API/web — one line>
- 🧠 Planner: <one line>
- 👨‍💻 Developer: <one line>
- 🧪 Tester: <one line>
- 🎨 UI developer: <screens, reference fidelity, differences — one line, or "n/a">
- 🔍 Review + 🔒 Audit (parallel): <one line>
- 🔧 Fixes applied: <one line>
- ✨ Polish: <Pint/PHPStan — one line>
- 🚦 Quality Gate: <PASS/FAIL — one line>
- 🚀 Ship: <commit / PR / migrate — one line>
- 📄 Documented: `docs/agent-workflow/<date>-<Model>.md`

## Next steps
<run migration if not auto-run, review the PR, add UI, anything left as TODO>
```

**Batch mode final report:** one summary table across all models — `<Model> | gate | tests | findings | shipped` — then the per-model one-liners.

## Rules
- **Read the project's architecture docs and follow its conventions** before planning — never assume a generic layout. Older and newer projects differ.
- Delegate to subagents; don't write the feature code yourself in the main thread.
- Keep the user informed at each phase transition with a one-line status.
- Never skip recon. In interactive mode get user approval before building; in `--auto` skip the approval prompt but **never bypass the safety gates** (dirty tree, model conflict, failed Quality Gate).
- Never run two writers in parallel. Always run review + audit in parallel. In batch mode, finish one model's full cycle before starting the next.
- The **Quality Gate is the source of truth** for success. Never commit, migrate, or open a PR on a FAIL. Emit the one-line `RESULT:` verdict for CI/logs.
- A FAIL loops back to FIX, but **hard-capped at 3 gate attempts** — the only feedback loop in the workflow. Stop early if a round produces no net change to the findings.
- On a failed gate in `--auto` (after retries are exhausted), DOCUMENT first, then roll back to a clean state with `git clean -fd -e docs/agent-workflow/` so the failure log survives (unless `--no-rollback`). Never leave the repo half-broken.
- Capture important decisions/notes during the build so future team members can maintain consistency.
- Always DOCUMENT (Phase 8) — even on failure — built from the real git diff, not memory. Then SHIP (Phase 9) and NOTIFY (Phase 10) only as the flags and gate allow.
