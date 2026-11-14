---
description: Two-phase OWASP security audit of a Laravel codebase using read-only auditor agents — Phase 1 finds & ranks vulnerabilities (optionally fixing Critical/High via the developer agent), Phase 2 re-checks for filter-evasion / bypass / complex-chain attacks and never edits code. Writes a severity-ranked report per phase.
argument-hint: "[path-or-scope]  [--fix] [--phase=1|2] [--out=docs/agent-workflow] [--commit|--pr]   e.g. app/Http --fix   |   --phase=2   |   --fix --pr"
---

You are the **security lead** orchestrating read-only auditor subagents to audit an existing Laravel codebase against the OWASP Top 10. Coordinate the team; do as little scanning yourself as possible — delegate to the agents. Confirm you are inside a Laravel project (`php artisan --version`); if not, tell the user and stop.

## Audit request
Arguments: $ARGUMENTS

Parse out the flags below, then treat whatever remains as the **scope** (a path, glob, or "the whole app"). If no scope is given, audit the application code under `app/`, `routes/`, `config/`, `database/`, and Blade views under `resources/views/`.

## Run modes & flags (parse these out first)

- **`--fix`** — After Phase 1's report is produced **and approved**, allow the **`laravel-developer`** agent to fix **Critical/High** findings only, then re-audit the changed files. **Without this flag the entire run is read-only** — it reports and never touches code. Phase 2 is **always** read-only regardless of this flag.
- **`--phase=1`** / **`--phase=2`** — Run only that phase. Default: run **Phase 1 then Phase 2**.
- **`--out=<dir>`** — Where to write the reports. Default `docs/agent-workflow/` (per this repo's CLAUDE.md §5). The user's original ask referenced `../SECURITY-REPORT-*.md` *outside* the repo — only write outside the project if they pass an explicit `--out`, and warn that files outside the repo won't be committed.
- **`--commit`** / **`--pr`** — On completion, commit the reports (and any `--fix` changes) — `--pr` also opens a GitHub PR via `gh`. Without either, leave everything in the working tree.

If `--fix` is set, the tree must be clean and on a dedicated branch (safety gate below). If a flag's prerequisite is missing (e.g. `--pr` but no `gh`/remote), fall back to the next-best action and say so — never fail the audit over shipping plumbing.

## ⚠️ Read the project's architecture FIRST — map every check to Laravel idioms

This is a Laravel app, **not** generic PHP. Before auditing, read `CLAUDE.md` / `architecture.md` / `docs/` and the existing code, and translate every OWASP check to this stack — otherwise the auditors report noise:

| Generic PHP check | Laravel reality to audit instead |
|---|---|
| PDO / prepared statements | Eloquent / Query Builder bindings; flag only `DB::raw`, `whereRaw`, `orderByRaw`, `havingRaw`, `DB::statement` with unbound input |
| `htmlspecialchars()` output encoding | Blade `{{ }}` auto-escaping vs unescaped `{!! !!}`; API Resources; `Js::from()` for inline JS |
| Raw PHP `session_*` flags | `config/session.php` (`http_only`, `secure`, `same_site`), `SESSION_*` env; session regeneration on login |
| `.htaccess` / `nginx.conf` exec rules | `config/filesystems.php` disks, public vs private storage, `Storage::disk('public')` exposure |
| Hand-rolled CSRF tokens | `VerifyCsrfToken` middleware, `web` group coverage, `@csrf`, any `$except` entries |
| Manual rate-limit code | `throttle` middleware, `RateLimiter::for()` in `AppServiceProvider`/`RouteServiceProvider`, Fortify/Sanctum login throttling |

Produce a short **Project Profile** (Laravel version, API/web, auth: Sanctum/Fortify/Breeze, session driver, storage disks, notable packages) and feed it into every auditor prompt. **Do not start auditing until recon is done.**

## The workflow

```
                       ┌── AUDIT (parallel auditors by domain) ──┐
RECON ─▶ PHASE 1 ──────┤                                         ├─▶ consolidate ─▶ REPORT-1
(profile)              └── one auditor per OWASP domain group ───┘        │
                                                                  [gate] (--fix only)
                                                                          ▼
                                                              FIX Critical/High (developer)
                                                                  ─▶ re-audit changed ─▶ update REPORT-1
PHASE 2 ─▶ EVASION AUDIT (parallel, read-only — NEVER fixes) ─▶ consolidate ─▶ REPORT-2
```

### Phase 0 — RECON & PRE-FLIGHT  (do this yourself, no agent)
Run in parallel:
- **Read architecture docs** — `CLAUDE.md`, `architecture.md`, `docs/`. Summarize conventions to respect.
- **Detect stack** — `php artisan --version`, `cat composer.json` (PHP version, auth packages, Pint/Larastan/Pest), `ls app/` (Action/Service/Repository layers? API or web?).
- **Dependency check** — note `composer.lock` presence; if `composer audit` is available, run it and fold known-CVE packages into the findings. Don't block on network failures — note "not run" instead.
- **`--fix` safety gates** *(only when `--fix` is set)* — `git status --short` must be clean; if dirty, stop (ask to commit/stash). Create a branch `security/audit-<date>` so fixes are isolatable and reversible. Without `--fix`, a dirty tree is fine (read-only).

Build the **Project Profile** and continue.

### Phase 1 — AUDIT  (parallel read-only auditors ⚡) → REPORT-1
Launch **`laravel-security-auditor`** subagents **in one message so they run concurrently** — they are read-only and cannot conflict. Split the OWASP surface across them by domain group so each goes deep rather than skimming everything:

- **Auditor A — Injection & access:** SQLi, Code/Command Injection, LFI/RFI, Path Disclosure, Directory Traversal, IDOR / broken access control.
- **Auditor B — Input/output & files:** XSS (reflected/stored/DOM — distinguish input allow-listing from output encoding), Arbitrary File Upload, mass assignment, mass data exposure.
- **Auditor C — Request, session & config:** CSRF, session security (HttpOnly/Secure/SameSite, fixation, timeout), rate-limiting / brute-force, hardcoded secrets & committed `.env`, security headers (CSP, X-Frame-Options, HSTS), logical 200-OK bypasses & sensitive data in error handling.

Pass each the **Project Profile** and the scope. Each returns findings ranked **Critical / High / Medium / Low** with `path:line`, the **attack** (how it's exploited), and a concrete **fix** — but applies nothing.

Consolidate all findings into one **de-duplicated, severity-ranked** list and **write REPORT-1** (format below). In interactive mode, show the user the Critical/High summary.

### Phase 1b — FIX  (only with `--fix`; needs approval) → laravel-developer
Skip entirely unless `--fix` is set. **Interactive:** show the Critical/High findings and **ask the user to approve** before any edit. **`--fix --auto`:** proceed but still never touch Medium/Low.

Launch the **`laravel-developer`** subagent with the approved **Critical/High** findings to fix them surgically (Laravel idioms: bound queries, FormRequest validation, Policies/Gates, `throttle`, `config/session.php`, security-header middleware). Then re-launch the auditor on the **changed files only** to confirm each fix closed the hole and introduced nothing new. Update REPORT-1 with a **Status** column (Open / Fixed / Verified). Cap fix→re-audit at **2 rounds** so it can't loop. The auditor never edits; only the developer does.

### Phase 2 — EVASION & BYPASS AUDIT  (parallel read-only auditors ⚡ — NEVER fixes) → REPORT-2
This phase **only reports** — it must not change code even when `--fix` was passed. Launch **`laravel-security-auditor`** subagents in parallel, each told to assume an attacker is actively trying to **defeat existing filters/validation**, and to evaluate — for each control found in Phase 1 — *whether it can be evaded*:

1. **XSS** — encoding gaps, `{!! !!}`, attribute/JS/URL contexts, mutation/DOM sinks, SVG/`mXSS`, double-encoding, polyglots.
2. **SQL Injection** — second-order/stored, JSON-path & `whereRaw` sinks, `LIKE`/wildcard & column-name injection, mass-assignment-driven queries.
3. **CSRF** — `$except` holes, SameSite gaps, JSON/method-override bypass, login CSRF, missing re-auth on sensitive actions.
4. **Remote File Inclusion** — dynamic includes/`view()`/wrappers, SSRF-style remote fetches.
5. **Arbitrary File Upload** — double-extension, MIME spoof, null-byte/polyglot files, SVG/HTML, path-controlled storage, executable upload dirs.
6. **Code Injection** — `eval`, `call_user_func`, dynamic class/method dispatch, unsafe `unserialize`, template injection.
7. **Local File Inclusion** — `../` traversal, `realpath`/allow-list bypass, wrapper tricks, log/session poisoning.
8. **Path Disclosure** — stack traces with `APP_DEBUG=true`, error responses leaking absolute paths, exposed `storage`/`.env`.
9. **Brute-force & HTTP rate-limiting** — throttle bypass via header/IP spoofing, key rotation, per-route gaps, missing lockout on auth.
10. **Complex / chained attacks** — multi-step exploits where each step returns a clean **HTTP 200** (logical bypass), and combinations that defeat a control only when chained.

For each control, state **Adequate / Evadable / Absent**, the bypass technique if evadable, and severity. Consolidate and **write REPORT-2**. Make no edits.

### Phase 3 — SHIP  (only if `--commit`/`--pr`)
Commit the report(s) (and `--fix` changes if any) with `security: OWASP audit — phase 1 & 2 reports` (+ co-author trailer). `--pr` pushes the branch and opens a PR with the reports as the body. No flag → leave in the working tree and print the next commands.

## Report format (write one file per phase under `--out`, default `docs/agent-workflow/`)
Run `mkdir -p <out>` first. Files: `<YYYY-MM-DD>-Security-Phase1.md` and `<YYYY-MM-DD>-Security-Phase2.md`.

```markdown
# Security Audit — Phase <1|2> (<Findings | Evasion & Bypass>)

**Date:** <DD/Mon/YYYY>
**Command:** `/laravel-security-audit <original arguments>`
**Mode:** <read-only / --fix> · **Scope:** <paths audited>
**Verdict:** <N Critical · N High · N Medium · N Low>   |   <Phase 2: N Evadable · N Absent controls>

---

## 🔴 Critical
### 1. <title> — `app/.../File.php:NN`
- **OWASP:** <category>   · **Status:** <Open / Fixed / Verified>   (Phase 1 with --fix only)
- **Attack:** <how an attacker exploits / evades it — concrete>
- **Fix:** <one concrete Laravel-idiomatic change>

## 🟠 High
...
## 🟡 Medium
...
## ⚪ Low
...

## ✅ Controls correctly in place
<reinforce good patterns found — e.g. "all queries use Eloquent bindings", "throttle:6,1 on login">

## 📦 Dependencies
<composer audit results, or "not run">
```
Tell the user the full path of each file written.

## Parallelism & safety rules (do not break)
- Auditors are **read-only** → always launch the domain auditors **in parallel** (one message, multiple agent calls). They can never conflict.
- **Only the `laravel-developer` agent may edit code, and only in Phase 1b under `--fix` after approval.** Auditors never fix.
- **Phase 2 never edits anything**, even with `--fix`.
- Map every OWASP check to Laravel reality (the table above) before reporting — no generic-PHP false positives.
- Verify before reporting: read the actual line, trace where input enters and lands, and confirm no mitigating control (global policy, middleware, observer) exists elsewhere. Never invent findings to look thorough; if a phase is clean, say so plainly.
- Default `--out` keeps reports inside the repo (`docs/agent-workflow/`); only write outside on an explicit `--out`, with a warning.

## Final report to the user
```markdown
# 🔒 Security Audit Complete — <scope>

**Phase 1:** <N Critical · N High · N Medium · N Low>  <(M fixed)  if --fix>
**Phase 2:** <N controls Evadable · N Absent — bypass-focused>
**Reports:** `<out>/<date>-Security-Phase1.md`, `<out>/<date>-Security-Phase2.md`
**Changes:** <read-only / N files fixed — committed / PR #<n> / in working tree>

## Top risks
- 🔴 <one line each for the Criticals>

## Next steps
<approve --fix run, patch the Highs, rotate any exposed secret, etc.>
```
