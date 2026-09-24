# SITREP — sigyard (Opportunity Radar)

**Date of report:** 2026-09-24 · **Evidence base:** local repo (read-only), git history, and GitHub API state for issues/PRs referenced by that history. No external services (n8n instance, Airtable, LLM APIs) were queried beyond the public GitHub repo metadata.

---

## 1. Snapshot

### What it is
sigyard (working title "Opportunity Radar", `PRD.md:1`) is a planned personal, single-user bot pipeline that scouts niche sources on a schedule, classifies raw signals as trend/gig/arbitrage with a relevance score, deduplicates them, turns qualified items into structured "opportunity cards" in Airtable for human review, and only after human approval drafts an implementation plan (`PRD.md:21-28`, `PRD.md:30-39`). As of this report the repository contains **governance/planning documentation, a Docker Compose deployment skeleton, and one export script — no pipeline code, no workflows, no prompts, no source list, and no Airtable schema file exist** (verified file listing below; `README.md:57-61` states the same). The repo's own status section says: "Scaffolding complete… No workflows, sources, or Airtable schema are built yet" (`README.md:59-61`). All product work is tracked as 23 GitHub issues (#2–#24), **all still OPEN** (GitHub API, `gh issue list`), plus 2 open PRs (#26, #27).

### Repo layout (top 2 levels)

```
sigyard/
├── AGENTS.md              # AI-agent conventions (109 lines)
├── PRD.md                 # product requirements (101 lines)
├── README.md              # project readme (65 lines)
├── WORKFLOW.md            # git flow, 5 milestones, issues #2–#24 (262 lines)
├── design.md              # architecture/schema decisions (233 lines)
├── LICENSE                # MIT
├── .gitignore
├── .opencode/             # local agent tooling
│   ├── skills/project-scaffolder/   # SKILL.md, templates/, references/ (tracked)
│   ├── node_modules/, package*.json # present on disk, gitignored
│   └── .gitignore
├── infra/
│   ├── Caddyfile          # TLS reverse proxy → n8n:5678
│   ├── docker-compose.yml # postgres + n8n + caddy
│   └── n8n.env.example    # env var template (placeholder values only)
└── scripts/
    └── export-workflows.sh # pulls workflows from a live n8n via API
```

**Absent (required by `design.md:136-157` but do not exist):** `sources/`, `prompts/`, `airtable/`, `n8n/` (all four directories missing; verified with `ls`).

**Languages / frameworks:** No application language code. Tracked content is Markdown (11 files), Bash (1), Docker Compose YAML (1), Caddyfile (1), env example (1), plus license/gitignore. GitHub reports `"language": null` for the repo. Stack *intended* per docs: n8n (self-hosted Docker), Postgres, Airtable, provider-agnostic LLM (Claude default), Caddy (`design.md:9-18`, `README.md:8-15`).

**Size:** 17 tracked files, ≈70 KB total content. Working directory 64 MB, dominated by **untracked** `.opencode/node_modules/` (gitignored via `.opencode/.gitignore`). GitHub repo `size` field: 37 KB.

### Git activity
| Metric | Value | Evidence |
|---|---|---|
| First commit | 2026-09-21 10:14:51 +0300 (`70c7f7d` "Initial commit") | `git log --reverse` |
| Last commit | 2026-09-21 13:24:01 +0300 (`f27190f`) | `git log -1` |
| GitHub `pushed_at` | 2026-09-21T10:24:03Z (≈ same moment) | GitHub API |
| Total commits | **8** (all on 2026-09-21; entire history is one day) | `git rev-list --count` |
| Commits last 30 days | 8 | `git log --since='30 days ago'` |
| Commits last 90 days | 8 | `git log --since='90 days ago'` |
| Contributors (git author identities) | **2 names, 1 human account**: `bkoimett <benkoimet@gmail.com>` (5 commits) and `Koimett Benjamin <57264008+bkoimett@users.noreply.github.com>` (3 commits — same GitHub user id 57264008) | `git shortlog -sn`, author emails |
| Branches | `main` (= `origin/main`), `chore/2-docker-compose-stack`, `chore/4-export-scripts` (checked out), `docs/fix-issue-numbering` | `git branch -vv` |
| Merged PRs | #1 (scaffold docs), #25 (issue-numbering fix) | GitHub API / merge commits `0f864a4`, `315a6c9` |
| Open PRs | #26 (`chore/2-docker-compose-stack`), #27 (`chore/4-export-scripts`) | GitHub API |
| Working tree | clean, no stashes | `git status`, `git stash list` |

**Important:** `main` tip (`315a6c9`) does **not** contain `infra/` or `scripts/` — those live only on the two open-PR branches (`88989af` → `06846c3` → `f27190f` sit on top of main). Cloning `main` alone yields docs only.

Days since last commit at report time: **3** (2026-09-21 → 2026-09-24).

---

## 2. PRD vs reality

**PRD located:** `PRD.md`, title "PRD: Opportunity Radar (working title)" (`PRD.md:1`). It is in the repo (committed `12c75b7`, PR #1).

### The 7 core V1 features (`PRD.md:30-39`)

| # | Feature | Status | Evidence |
|---|---|---|---|
| 1 | Source scouting | **NOT STARTED** | `sources/sources.yaml` missing (dir absent); `n8n/workflows/` missing; issues #9, #10 OPEN |
| 2 | Classification (tag + relevance score) | **NOT STARTED** | `prompts/classify.md` missing (`prompts/` absent); no LLM call anywhere in tracked files; issues #12, #13 OPEN |
| 3 | Dedup | **NOT STARTED** | Mechanism exists only as a design decision (`design.md:34`, `design.md:85-87`, `design.md:174-179`); no scout to run it; issue #11 OPEN |
| 4 | Opportunity card generation | **NOT STARTED** | `prompts/triage.md` missing; no workflow JSON; issues #14, #15 OPEN |
| 5 | Review queue (Airtable approve/reject) | **NOT STARTED** | `airtable/base-schema.md` missing; base not evidenced as created; issues #7, #8 OPEN |
| 6 | Approval trigger → draft plan | **NOT STARTED** | `prompts/draft-plan.md` missing; no review-trigger/draft-plan workflows; issues #16, #17, #18 OPEN |
| 7 | Classification feedback loop (labeled dataset) | **NOT STARTED** | `labels` table exists only in design (`design.md:51-56`); no rows, no export path; issues #19, #20 OPEN |

**Summary: 0/7 implemented.** The only completed work relative to the plan is part of Milestone 1 (`WORKFLOW.md:109-113`): issue #2's compose stack and issue #4's export script exist as commits on unmerged branches (PRs #26/#27 open). Issues #3 (stand up n8n on VPS) and #5 (enroll credentials) have **no repo evidence** either way → externally UNKNOWN.

### Source Selection pre-build gate (`PRD.md:43-44`)

- **Gate status: NOT PASSED** — the gate requires the source list be "finalized and justified" before any n8n nodes are written; `sources/sources.yaml` does not exist (issue #6 OPEN). `README.md:40-41` and `design.md:226-228` both restate the gate.
- **Ordering side-effect:** because no n8n workflow nodes exist anywhere in the repo, the gate's core prohibition ("No n8n nodes are written until the source list is finalized") has **not been violated** — there are zero nodes to violate it with.
- **Sources actually configured: none.** Empty list. Therefore no source is classified here as niche/edge vs generic aggregator — that determination cannot be made until `sources/sources.yaml` exists. Intended schema (slug, category trend|gig|arbitrage, type, URL, schedule, key ref, rationale) is specified at `design.md:145` and `WORKFLOW.md:168-170`.

### Built but NOT in the PRD
| Artifact | In PRD? | Where specified |
|---|---|---|
| `infra/docker-compose.yml` + Caddyfile + env example | Stack named in `PRD.md:61-65` (n8n/Docker/VPS); exact compose layout is design's call | `design.md:13-15`, `WORKFLOW.md:144-148` |
| `scripts/export-workflows.sh` | Not in PRD; process tooling | `design.md:155`, issue #4 |
| `.opencode/skills/project-scaffolder/` (SKILL.md + 4 templates + references) | **Not in PRD and not in `design.md` §6 folder structure** — agent scaffolding tooling used to generate repo docs | `git show f27190f`; folder structure at `design.md:136-157` omits `.opencode/` |
| `AGENTS.md`, `WORKFLOW.md` governance docs | Not product features; process layer | `PRD.md` silent on process docs |

### PRD non-goals (`PRD.md:12-15`, `PRD.md:49-53`) — built anyway?
**None.** Non-goals: no auto-execution, no multi-tenant UI, no mobile app, no auto-drafting pitches pre-approval, no Slack/Telegram notifications, no multi-user config UI, no custom real-time dashboard. The repo contains no code that implements any of these. (`design.md:69-71` explicitly reserves no schema columns for them.)

---

## 3. Architecture as built

### n8n workflows
**Exported workflows: zero.** `n8n/workflows/` does not exist; a recursive search finds no `.json` workflow exports anywhere tracked.

| Planned role (per docs) | File | Status |
|---|---|---|
| scout (RSS) | — | not built (issue #9) |
| scout (API/search) | — | not built (issue #10) |
| classify | — | not built (issue #13) |
| triage | — | not built (issue #15) |
| review-trigger | — | not built (issue #16) |
| draft-plan | — | not built (issue #18) |
| error/alert workflow | — | not built (issue #23) |
| measurement workflows | — | not built (issues #21, #22) |

Triggers/schedules: **none defined in repo data** — schedules were to live per-source in `sources/sources.yaml` (`design.md:77-80`), which is missing. External services *intended* for workflows: Airtable API, LLM provider, per-source APIs (`design.md:109-126`) — none referenced by any executable artifact.

What *does* exist operationally:
- **`infra/docker-compose.yml`** (72 lines): services `postgres` (`postgres:16-alpine`, healthcheck `pg_isready`), `n8n` (`n8nio/n8n:${N8N_VERSION:-stable}`, Postgres-backed via `DB_TYPE=postgresdb`, `N8N_BASIC_AUTH_ACTIVE=true`, HTTPS + `WEBHOOK_URL`, `EXECUTIONS_DATA_PRUNE=true` / `EXECUTIONS_DATA_MAX_AGE=168` (7-day execution retention), healthcheck `/healthz`), `caddy` (`caddy:2-alpine`, ports 80/443).
- **`infra/Caddyfile`** (3 lines): `{$DOMAIN}` → `reverse_proxy n8n:5678`.
- **`scripts/export-workflows.sh`** (85 lines): paginated GET `/api/v1/workflows` with `X-N8N-API-KEY`, writes one pretty-printed JSON per workflow into `OUTPUT_DIR` (default `n8n/workflows/`). Header documents credential-ID rebind caveat (`scripts/export-workflows.sh:5-8`, matches `design.md:128-132`). Requires `curl`, `jq`.

### Airtable
**As built: nothing.** No `airtable/base-schema.md`, no schema application script, no API client code.

**Schema as defined (design only, `design.md:20-67`):** one base `sigyard`, three tables:

| Table | Key fields | Purpose |
|---|---|---|
| `signals` | Title, Source, Category (trend\|gig\|arbitrage), URL, Body, **Content hash (unique)**, Fetched at | raw pulled item |
| `cards` | Signal (link), Classification, Relevance score 0–100, Summary, Why it matters, Effort estimate, Possible actions, Money potential, Expiry/urgency, **Status (queued→approved\|rejected)**, Reviewed at, Implementation plan | review unit |
| `labels` | Content hash, Item text, Decision (approve\|reject), Reviewed at, Source; unique pair (Content hash, Decision) | append-only feedback ledger |

**How items get in/out (designed, not implemented):** scouts insert into `signals` (dup insert rejected → treated as "already seen", `design.md:174-179`); triage inserts `cards` with `Status=queued`; human reviews in the Airtable grid (outside n8n, `design.md:100-103`); review-trigger workflow polls status changes and appends `labels` (`WORKFLOW.md:220-223`); draft-plan writes `Implementation plan` only when approved AND plan empty (`design.md:180-186`).

### LLM usage
**No LLM is called anywhere in the repo** — no API client code, no workflow JSON, no prompt files.

- **Provider/model (intended):** "Provider chosen by environment (Claude default; free tier as fallback)" (`design.md:17`); PRD defers Claude-vs-free-tier until after the first 100 reviewed items (`PRD.md:70`, `design.md:222-225`). Actual model: **UNKNOWN / not selected**.
- **Where it would run:** three workflows (classify, triage, draft-plan), each loading a prompt file (`design.md:81-84`, `design.md:116-122`).
- **Prompts:** `prompts/classify.md`, `prompts/triage.md`, `prompts/draft-plan.md` are **specified but do not exist**. Intended jobs (filenames + `design.md:147-149`, `WORKFLOW.md:198-211`): classify → tag trend/gig/arbitrage + numeric relevance; triage → fill card fields (summary, why it matters, effort, actions, money potential, urgency); draft-plan → implementation plan for approved cards. **No prompt text exists to quote.**
- **Classification & scoring mechanics:** category is a three-way tag; relevance is a 0–100 number field on the card (`design.md:39-40`). How the score is computed (thresholds, what gets triaged) is **not specified anywhere in the repo** → UNKNOWN beyond "LLM produces it".

### Dedup approach
**Designed only, single mechanism:** uniqueness on `signals.Content hash` enforced by Airtable (`design.md:34`, `design.md:59-61`, `design.md:85-87`). Normalization recipe: "lowercase URL stripped of tracking params, falling back to a hash of title + body" (`design.md:86-87`). Race handling: second insert rejected → "already seen", not an error; explicitly "no second dedup store" (`design.md:174-179`, `AGENTS.md` ground rule 5). **Implementation: none** (issue #11 open).

### Feedback loop / labeled dataset
**Does not exist.** Designed as append-only `labels` table with immutable rows (`design.md:51-67`); export path and few-shot re-injection are issues #19 and #20 (both OPEN). **Row count: 0 in repo** (no data files at all); whether an Airtable base with rows exists externally is UNKNOWN (issue #8 to create/apply the base is still open, which is evidence *against* it, but not proof).

---

## 4. Operational state

### Has it ever run end to end?
**No evidence in the repo.** Searched for and found **zero**: execution logs, sample outputs, fixtures, screenshots/images, CSV/JSON data files (only `package*.json` under `.opencode/`), test files, or CI run artifacts. Issue **#24 "Production deploy and first end-to-end run" is OPEN**. Issues #3 (stand up n8n) and #11 (verify dedup) are OPEN. **Items processed: not determinable from repo; no artifact suggests any item was ever processed.** Whether a private n8n/Airtable outside the repo has run anything → UNKNOWN (see §6).

### Deployment setup
| Item | Detail | Evidence |
|---|---|---|
| Container definition | `infra/docker-compose.yml` — postgres, n8n, caddy | file exists (branch `chore/2-docker-compose-stack` / open PR #26; **not on `main`**) |
| Dockerfile | none (uses upstream images `postgres:16-alpine`, `n8nio/n8n`, `caddy:2-alpine`) | compose file |
| Hosting target (documented) | single VPS + Docker Compose; Caddy auto-TLS via Let's Encrypt (comment in env example); PRD also floated Oracle free tier / Render / ~$3–5 VPS | `design.md:14`, `infra/n8n.env.example:5`, `PRD.md:78-80` |
| Hosting target (actual) | **UNKNOWN** — no deploy scripts, no cloud config, issue #3 open | — |

**Env var names required (names only; values are `changeme` placeholders in the committed example — not secrets):**
- `infra/.env` (from `n8n.env.example`): `DOMAIN`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `N8N_BASIC_AUTH_USER`, `N8N_BASIC_AUTH_PASSWORD`, `N8N_ENCRYPTION_KEY`, `GENERIC_TIMEZONE`, `N8N_VERSION`
- Export script: `N8N_BASE_URL`, `N8N_API_KEY` (optional `OUTPUT_DIR`) — `scripts/export-workflows.sh:18-20`
- Later (per docs, not yet any config file): Airtable base id per environment, LLM credential, source keys — `design.md:200-202`, `README.md:33-34`

**To run locally (as documented):** Docker + compose; `cd infra && cp n8n.env.example .env` and fill values; `docker compose up -d`; a domain with DNS pointing at the host for Caddy certs; then n8n UI setup steps (`README.md:19-41`) — most of which reference files that don't exist yet (see README accuracy below). `curl` + `jq` for the export script.

### Tests, CI, docs, README accuracy
| Area | Finding |
|---|---|
| Tests | **None** (no test files, no test framework, no test commands) |
| CI | **None** — `.github/` does not exist (no workflows, no dependabot) |
| Docs quality | High *quantity and internal consistency* for planning: PRD → design → AGENTS → WORKFLOW cross-reference each other with section anchors; 23 issues mirror `WORKFLOW.md` §6 exactly (verified titles/numbers via GitHub API). Docs are the project's main artifact. |
| README accuracy | **Status section accurate** (`README.md:57-61` matches reality). **Setup section has concrete errors:** (1) `README.md:25` says set `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ENCRYPTION_KEY` — those names appear **nowhere** in the compose/env files; actual names are `N8N_BASIC_AUTH_USER`, `N8N_BASIC_AUTH_PASSWORD`, `N8N_ENCRYPTION_KEY`, plus `DOMAIN`/`POSTGRES_*` (undefined in README). (2) `README.md:32` instructs running `scripts/apply-base-schema.sh` — **file does not exist** (also promised at `design.md:156`). (3) Steps 1–3 point at `airtable/base-schema.md`, `sources/sources.yaml`, `n8n/workflows/` — all missing (consistent with "nothing built", but presented as runnable setup steps). |
| Related doc drift | `design.md:98` refers to "`N8N_BASIC_AUTH` in `infra/.env`" — compose actually uses `N8N_BASIC_AUTH_ACTIVE` / `_USER` / `_PASSWORD` (`infra/docker-compose.yml:31-33`), and the example file doesn't define `N8N_BASIC_AUTH_ACTIVE` at all (it's hardcoded in compose). |

---

## 5. Health check

### TODO / FIXME / HACK comments
Only one textual match repo-wide (excluding `.git`, `node_modules`):
- `WORKFLOW.md:81` — `follow-up/TODO left for a later issue.>` — this is **template copy inside the PR-description example**, not an actionable code TODO.

**No code-level TODO/FIXME/HACK markers exist** (there is almost no code).

### Known bugs / broken / half-finished pieces
1. **`scripts/apply-base-schema.sh` missing** but invoked by `README.md:32` and listed as existing in `design.md:156` — following the README fails immediately.
2. **README env var names wrong** (`README.md:25`: `ADMIN_EMAIL`/`ADMIN_PASSWORD`/`ENCRYPTION_KEY` vs actual `N8N_BASIC_AUTH_USER`/`N8N_BASIC_AUTH_PASSWORD`/`N8N_ENCRYPTION_KEY`) — documented setup cannot work as written.
3. **`main` does not contain the infra or export script** — PRs #26 and #27 open since 2026-09-21; anyone cloning `main` gets docs only.
4. **Commit `f27190f` (project-scaffolder) has no `(#issue)` reference**, violating `AGENTS.md:12-13` ("Every commit in this repo references the GitHub issue") and `WORKFLOW.md:52-54`. It also sits on `chore/4-export-scripts`, mixing unrelated work onto an issue-scoped branch (`WORKFLOW.md:24-25`: "Don't scope-creep one branch").
5. **Half of Milestone 1 unfinished in-repo:** issues #3 (VPS standup) and #5 (credentials) have no artifacts; #2 and #4 are done-but-unmerged.
6. **Execution retention is 7 days** (`EXECUTIONS_DATA_MAX_AGE: "168"`, `infra/docker-compose.yml:39-40`) — old execution history self-deletes.
7. **`compose` file carries obsolete top-level `version: "3.8"`** (`infra/docker-compose.yml:1`) — modern Compose warns/ignores it (cosmetic).
8. **Everything beyond Milestone 1 is entirely unbuilt** (21 of 23 issues open; all 7 product features NOT STARTED).

### Dependencies that look outdated / abandoned
- **No application dependency manifest exists** (no package.json/requirements/go.mod at repo root).
- Docker images: `n8nio/n8n:${N8N_VERSION:-stable}` — **floating `stable` tag by default**; the env example itself comments "use a specific version for reproducibility" (`infra/n8n.env.example:24-25`) but ships `N8N_VERSION=stable`. `postgres:16-alpine`, `caddy:2-alpine` — major-pinned tags only, no digests.
- Untracked local tooling: `.opencode/package.json` pins `@opencode-ai/plugin` `1.18.31` (agent scaffolding only; gitignored — not a product dependency).
- Nothing in-repo is "abandoned" in the classic sense because nothing has had time to rot: **the whole repo is 3 days old.**

### Cost drivers (pipeline dependencies, planned vs actual)
| Service | Status in repo | Cost relevance (per docs) |
|---|---|---|
| Claude API (or free-tier LLM) | intended (`PRD.md:64`, `PRD.md:86-88`); **not wired**; provider decision deferred (`PRD.md:70`) | per-token spend once classify/triage run; quantity unknown |
| Airtable | intended (`PRD.md:63`, `PRD.md:90-92`); **not wired** | PRD expects free tier; limits not analyzed in repo |
| VPS hosting for n8n | compose ready; **deploy evidence absent** (`WORKFLOW.md` #3 open) | PRD estimates ~$3–5/mo or free tier (`PRD.md:79`) |
| n8n self-hosted | free (license/docs say self-hosted free, `PRD.md:22`) | $0 |
| Per-source API keys | **zero sources configured** | unknown until gate #6 closes |
| Caddy / Let's Encrypt | free | $0 |

**No paid service is demonstrably being spend on right now from repo evidence** (nothing is deployed/wired in-repo).

### Biggest technical risks visible in the code/docs
1. **Zero product functionality exists** — risk is not code quality; it is that 7/7 features and 21/23 issues remain, with all activity confined to a single day (2026-09-21).
2. **Pre-build gate is a hard blocker:** scouting (and everything downstream) cannot start until `sources/sources.yaml` is written with niche, justified sources (`PRD.md:43-44`, `README.md:40-41`) — that file does not exist, so the project's core differentiator (niche edge vs generic aggregator) has **never been instantiated as data**.
3. **Split-brain between `main` and working branches:** infra/scripts live only behind open PRs #26/#27; deploys or docs reading `main` diverge from reality.
4. **Silent-failure class of bugs is designed for but not built:** design requires loud failures via error workflow + email (`design.md:213-218`); issue #23 open — a deployed scout could wedge invisibly once built.
5. **Env/doc mismatches (README + design vs compose)** guarantee first-run friction for anyone following docs literally.
6. **Credential portability friction is accepted, not solved:** every workflow import needs manual credential re-selection (`design.md:128-132`, `scripts/export-workflows.sh:5-8`).
7. **Non-reproducible n8n version** (`stable` floating tag) — behavior of basic-auth env vars and API can shift under you between deploys.
8. **No tests/CI** — the only executable artifact (`export-workflows.sh`) is untested; jq/curl pagination edge cases (empty page, API errors) are handled only by `set -euo pipefail` + `curl -sSf`.
9. **7-day execution log pruning** limits post-incident forensics.
10. **Single-user internet-exposed n8n protected only by basic auth** (`design.md:97-99`, compose `N8N_BASIC_AUTH_ACTIVE`) — explicitly called out as the trust boundary; no 2FA/SSO in scope for V1.

---

## 6. Open questions (not determinable from the repo — answer these yourself)

1. **Has the compose stack ever been brought up on any machine** (local or VPS)? Issue #3 is open and no logs/artifacts exist here — but a private server wouldn't show up in git.
2. **Does any n8n instance exist right now, and does it contain workflows that were never exported?** The export script exists precisely because exports lag reality; zero JSON in `n8n/workflows/` could mean "never built" or "built but never exported."
3. **Do the dev/prod Airtable bases exist?** How many rows in `signals` / `cards` / `labels`? (Issue #8 open suggests not; can't verify externally.)
4. **Have external accounts/keys been provisioned** (Airtable PAT, Anthropic key, any source API keys, VPS)? Credentials live only in n8n/`.env` by design (`design.md:104-107`) and are invisible to the repo.
5. **Why did all activity stop on 2026-09-21?** One-day burst (≈3 hours wall-clock from first to last commit), then 3 days of silence as of this report. Was the pause intentional (awaiting advisor review), blocked, or abandoned-in-place?
6. **Were PRs #26/#27 left open deliberately pending review**, or was the intent to merge and continue from `main`?
7. **What is the actual niche/source strategy?** The PRD's whole value thesis is "not TechCrunch/HN generic feeds" (`PRD.md:44`) — which niche, which categories (trend/gig/arbitrage mix), which sources were you considering? Nothing is written down.
8. **LLM provider preference today:** still "decide after first 100 items" (`PRD.md:70`), or do you already know whether you'll pay for Claude?
9. **Hosting preference:** Oracle free tier vs Render vs cheap VPS (`PRD.md:78-80`) — never chosen in-repo.
10. **How many opportunities have you actually acted on manually** (outside this system)? PRD success metric #8.4 wants ≥1 real action/month from the queue (`PRD.md:59`) — baseline is unknowable from the repo.
11. **Is "sigyard" the intended product name** vs the PRD's "Opportunity Radar" working title? (Repo/remote are `sigyard`; docs title differs.)
12. **Who/such generated the scaffolding?** The committed `.opencode/skills/project-scaffolder/` templates match the repo's own doc structure — was this entire first day agent-produced scaffolding awaiting human execution, or human-driven? (Affects how much of the "plan" you actually endorse.)
13. **Is there a deadline or external commitment** behind this (advisor meeting aside)? Repo shows no dated milestones beyond GitHub's default.
14. **Do you still want V2 (multi-user, reusable config)** as stated in `PRD.md:10`, or is V1-only personal use the real target? Nothing in the repo tests V2 demand either way.

---

## 7. Raw facts appendix

### Key files (tracked) — one line each

| Path | Description |
|---|---|
| `PRD.md` | Product requirements: problem, goal, non-goals, 7 V1 features, source pre-build gate, success metrics, tech stack, external setup checklist (101 lines) |
| `design.md` | Architecture decisions: stack table, Airtable 3-table schema, ownership boundaries, secrets policy, integrations, folder structure, concurrency/idempotency, environments, observability, open decisions (233 lines) |
| `AGENTS.md` | Ground rules and DoD checklist for AI/human contributors (109 lines) |
| `WORKFLOW.md` | Branching/commit conventions, 5 milestones, full issue list #2–#24 with descriptions (262 lines) |
| `README.md` | Project overview, stack, setup steps (contains env-var name errors), doc index, honest status line (65 lines) |
| `infra/docker-compose.yml` | postgres + n8n + caddy service definitions, healthchecks, basic auth env wiring (72 lines) |
| `infra/n8n.env.example` | Env template: DOMAIN, POSTGRES_*, N8N_BASIC_AUTH_*, N8N_ENCRYPTION_KEY, GENERIC_TIMEZONE, N8N_VERSION — placeholder `changeme` values only (25 lines) |
| `infra/Caddyfile` | `{$DOMAIN}` reverse_proxy to n8n:5678 (3 lines) |
| `scripts/export-workflows.sh` | Bash: paginate n8n public API, dump workflows as JSON to `n8n/workflows/` (85 lines) |
| `LICENSE` | MIT |
| `.gitignore` | Standard Node gitignore incl. `.env` / `.env.*` with `!.env.example` exception (note: committed example is named `n8n.env.example`, which is not matched by `.env.*` anyway) |
| `.opencode/skills/project-scaffolder/SKILL.md` | Agent skill that generated this repo's doc scaffolding (7.7 KB) |
| `.opencode/skills/project-scaffolder/templates/*.md` | Templates for AGENTS/README/WORKFLOW/design docs |
| `.opencode/skills/project-scaffolder/references/avoid-ai-slop.md` | Writing-quality reference for the scaffolder |

**Not present (planned):** `sources/sources.yaml`, `prompts/{classify,triage,draft-plan}.md`, `airtable/base-schema.md`, `n8n/workflows/*.json`, `scripts/apply-base-schema.sh`.

### Secrets check
No committed secrets, API keys, tokens, or real credentials found (pattern scan across tracked files, excluding lockfile URL noise). `infra/n8n.env.example` contains only `changeme` placeholders. `.gitignore:69-71` excludes `.env` / `.env.*`. **Nothing to flag.**

### Last 20 commits (entire history: 8 commits, all 2026-09-21)

| # | Hash | Date (ISO, local +0300) | Author | Message |
|---|---|---|---|---|
| 1 (oldest) | `70c7f7d` | 2026-09-21 10:14:51 | Koimett Benjamin | Initial commit |
| 2 | `12c75b7` | 2026-09-21 12:14:46 | bkoimett | docs: scaffold project foundation (PRD, design, AGENTS, WORKFLOW, README) |
| 3 | `0f864a4` | 2026-09-21 12:15:13 | Koimett Benjamin | Merge pull request #1 from bkoimett/docs/project-scaffold |
| 4 | `416f729` | 2026-09-21 12:28:12 | bkoimett | docs: fix issue numbering in WORKFLOW.md to match live GitHub |
| 5 | `315a6c9` | 2026-09-21 12:28:41 | Koimett Benjamin | Merge pull request #25 from bkoimett/docs/fix-issue-numbering |
| 6 | `88989af` | 2026-09-21 12:31:32 | bkoimett | feat(infra): add docker-compose stack for n8n, postgres and caddy (#2) — *branch `chore/2-docker-compose-stack`, PR #26 open, not on main* |
| 7 | `06846c3` | 2026-09-21 12:34:18 | bkoimett | chore(scripts): add workflow export script (#4) — *on `chore/4-export-scripts`, PR #27 open* |
| 8 (newest) | `f27190f` | 2026-09-21 13:24:01 | bkoimett | feat(scaffolder): add project scaffolder templates and documentation — *no (#issue) ref; same branch as #7* |

### GitHub tracker snapshot (public repo `bkoimett/sigyard`, queried 2026-09-24)
- Created 2026-09-21T07:14:50Z · last push 2026-09-21T10:24:03Z · default branch `main`
- **23 open issues:** #2–#24 (titles match `WORKFLOW.md` §6 exactly); **0 closed issues**
- **PRs:** #1 MERGED (scaffold), #25 MERGED (issue-numbering fix), #26 OPEN (docker-compose stack), #27 OPEN (export scripts)
- `open_issues_count`: 25 (= 23 issues + 2 PRs)

### Milestone progress (derived from open/closed issues only)

| Milestone (`WORKFLOW.md:109-132`) | Issues | Closed | State |
|---|---|---|---|
| M1 Project Setup & Infrastructure | #2–#5 | 0 (PRs for #2/#4 open, work exists on branches) | partial, unmerged |
| M2 Sources & Data Foundation | #6–#11 | 0 | not started |
| M3 Classification & Triage | #12–#15 | 0 | not started |
| M4 Review, Approval & Feedback | #16–#20 | 0 | not started |
| M5 Measurement, QA & Launch | #21–#24 | 0 | not started |

---

*End of SITREP. Facts only; no continue/pivot/park recommendation is included, per request.*
