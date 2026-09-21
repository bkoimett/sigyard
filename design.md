# Design Document — Opportunity Radar

This document records the architecture and schema decisions for this
project. It exists so both humans and AI agents building on this repo make
consistent choices instead of re-deriving architecture per feature. Read
it together with `PRD.md` (what to build) and `AGENTS.md` (coding
conventions derived from these decisions).

## 1. Stack

| Layer | Choice | Why |
|---|---|---|
| Orchestration | n8n, self-hosted via docker-compose | PRD §5 names n8n as the orchestrator; V1 is a scheduled, single-user pipeline, so n8n's scheduler and node model cover the whole flow without custom job code |
| Hosting | VPS, Docker Compose | PRD §9 leaves the host open; a single VPS keeps n8n, Postgres, and the reverse proxy in one deployable unit and stays on 24/7, which the <24h signal-to-queue target (PRD §8) needs |
| n8n backing database | Postgres (`infra/docker-compose.yml`) | n8n's recommended production database; the compose stack survives restarts without the fragility of colocated SQLite, and Postgres is right there in the same compose file |
| Application data | Airtable, two bases (dev + prod) | Locked by PRD §9 (cleaner n8n API and better triage views than Notion); two bases keep test runs out of the real review queue |
| LLM | Provider chosen by environment (Claude default; free tier as fallback) | PRD §10 defers Claude vs free tier until after the first 100 items; the workflows must not be coupled to one vendor |
| Access control | n8n basic auth; Airtable account-level access | V1 is personal and single-user (PRD §3), so no multi-tenant auth or user system exists |

## 2. Data model (v1)

All application data lives in one Airtable base called `sigyard`. Three
tables, plus one config artifact: sources are configuration, per PRD §6's
config-driven note, so they live in the repo (`sources/sources.yaml`), not
in Airtable.

```
signals                     one raw item pulled from a source
  Title                     single line text
  Source                    single line text, matches a slug in sources/sources.yaml
  Category                  single select: trend | gig | arbitrage
  URL                       url
  Body                      long text
  Content hash              single line text, only allow unique values
  Fetched at                date

cards                       one decision-ready opportunity, reviewed by the user
  Signal                    link to signals record
  Classification            single select: trend | gig | arbitrage
  Relevance score           number 0-100
  Summary                   long text          # what it is
  Why it matters            long text
  Effort estimate           single line text
  Possible actions          long text
  Money potential           single line text
  Expiry / urgency          long text
  Status                    single select: queued | approved | rejected
  Reviewed at               date
  Implementation plan       long text          # written by the draft-plan workflow after approval

labels                      one immutable row per approve/reject decision (the feedback dataset)
  Content hash              single line text, matches signals.Content hash
  Item text                 long text          # snapshot of the signal text at review time
  Decision                  single select: approve | reject
  Reviewed at               date
  Source                    single line text   # carried over for per-source trend analysis
```

Uniqueness: `signals.Content hash` is unique (Airtable enforces it) and is
the dedup key. `(labels.Content hash, labels.Decision)` is unique so a
doubled trigger can never append the same decision twice.

Cards are the unit the user reviews; label rows are the unit the feedback
loop reads. They are separate on purpose: `labels` is an append-only
decision ledger, so re-reviewing a card later never rewrites history that
the V1.5 few-shot step or the false-positive metric depends on (PRD §6
feature 7, V1.5 note).

Nothing in this schema reserves columns for the PRD §7 backlog
(notifications, multi-user, custom dashboard). Those are external channels
or a separate app in V2, not extensions of these tables.

## 3. Core business logic

Four things have a single owner each:

- **Source list**: `sources/sources.yaml` is the only definition of what
  gets pulled, from where, at what interval, and with what rationale. The
  scout workflows read it. PRD §6's pre-build gate says no scouting
  workflow exists until this file is finalized.
- **Prompts**: `prompts/classify.md`, `prompts/triage.md`, and
  `prompts/draft-plan.md` are the only home of LLM prompt text. The three
  LLM workflows load their prompt from a file; no node carries inline
  prompt text or a copy of another prompt's logic.
- **Dedup**: the unique `signals.Content hash` field is the single dedup
  mechanism. All scout workflows use the same normalization (lowercase URL
  stripped of tracking params, falling back to a hash of title + body).
- **Card status**: `cards.Status` is a state machine
  (`queued -> approved | rejected`). Only the review-trigger workflow
  transitions it, and only the draft-plan workflow writes
  `cards.Implementation plan`, guarded so a plan is written once per card.

## 4. Authorization & secrets

Single-user, so the trust boundaries are small, but they are explicit:

- The n8n instance is reachable over the internet and requires basic auth
  (`N8N_BASIC_AUTH` in `infra/.env`). Nothing is protected by the obscurity
  of its URL; a future webhook trigger must require an n8n credential too.
- The Airtable base is private to the user's Airtable account. The token
  n8n uses has read/write scope on the `sigyard` base only. The user
  reviews and approves directly in the Airtable grid, never through a
  public surface.
- API keys (Airtable token, LLM key, per-source keys) live in n8n
  credentials or `infra/.env`, never in committed workflow JSON,
  `sources/sources.yaml`, or prompts. This is checked at commit time, not
  assumed.

## 5. External integrations

**Airtable.** All programmatic access goes through n8n's Airtable nodes
bound to one credential whose base id and table names come from env
config, not hardcoded workflow text. Human review is direct in the Airtable
UI, outside n8n entirely.

**LLM.** The integration boundary is the `prompts/` directory plus an
environment-selected credential, not a code interface. The classify,
triage, and draft-plan workflows each load their prompt from a file and
call the LLM credential configured for the current environment. Swapping
providers means re-pointing that credential in those three workflows and
changing the environment's provider name; the prompt files and the card
fields they produce do not change.

**Source APIs.** Sources that need a key have that key in an n8n
credential referenced by slug from `sources/sources.yaml`. Scout workflows
are plain HTTP nodes; no source SDK is imported anywhere.

Workflow import caveat: n8n binds exported workflow JSON to credential ids
that do not survive a clone. Importing a committed workflow into a new
instance requires re-selecting credentials by hand. This is accepted V1
friction and is documented in the export script, not worked around with
embedded keys.

## 6. Folder structure

```
sigyard/
├── PRD.md
├── design.md
├── AGENTS.md
├── WORKFLOW.md
├── README.md
├── infra/                     # deployment only: docker-compose (n8n, Postgres, reverse proxy), n8n.env.example
├── sources/
│   └── sources.yaml           # the source list: slug, category, type, URL, schedule, key ref, rationale
├── prompts/
│   ├── classify.md            # tag a signal trend/gig/arbitrage + relevance score
│   ├── triage.md              # turn a scored signal into an opportunity card
│   └── draft-plan.md          # draft an implementation plan for an approved card
├── airtable/
│   └── base-schema.md         # tables/fields/views for the sigyard base; source of truth for schema
├── n8n/
│   └── workflows/             # exported workflow JSON, one file per bot role plus the review-trigger
└── scripts/
    ├── export-workflows.sh    # pull the running instance's workflows into n8n/workflows/
    └── apply-base-schema.sh   # create/apply the Airtable base from base-schema.md (optional)
```

What does not belong where:

- `n8n/workflows/` is generated output only. Workflow JSON is exported
  from the running instance, never hand-written or merged as a new
  workflow.
- Prompt text never lives inside a node; that is what makes provider swaps
  and prompt iteration cheap.
- Secrets never live in `sources/`, `prompts/`, or `n8n/`.
- Airtable schema changes never happen first in the UI;
  `airtable/base-schema.md` is edited first.

## 7. Concurrency & idempotency

Two races exist in this pipeline, both cheap to design for now:

- **Duplicate signals from overlapping scans.** Two scout runs can fetch
  the same item in the same window and both try to insert.
  `signals.Content hash` is a unique-enforced Airtable field, so the second
  insert is rejected by Airtable. Scout nodes treat a rejected insert as
  "already seen" and continue, never as an error. There is no second dedup
  store.
- **Approval double-fire.** The review-trigger polls the cards table; two
  polls can both observe `Status = approved` before a plan exists. The
  draft-plan workflow only writes when `Status = approved` AND
  `Implementation plan` is empty, so the second run matches zero rows and
  no-ops. Label appends are guarded by uniqueness on
  `(labels.Content hash, labels.Decision)`, so the same decision cannot
  appear twice.

No money or inventory moves through this system, so nothing else needs
locking.

## 8. Environments

Two environments, fully separate:

- **Development**: a dev Airtable base plus a local or scratch n8n +
  Postgres instance. Used for building and testing workflows without
  polluting the real queue.
- **Production**: the VPS stack and the real `sigyard` base.

Everything environment-specific routes through env config: Airtable base
id, LLM provider and credential, source keys. The rule is that a dev
instance never writes to the production base and vice versa. An accidental
cross-wire is the worst bug this project can ship, because it pollutes the
exact data the success metrics measure (PRD §8).

## 9. Observability

- **The PRD §8 metrics need the timestamps this schema already keeps.**
  Signal-to-queue latency is `cards` creation minus `signals.Fetched at`
  (target <24h). The false-positive trend is `labels` rows compared over
  time by decision and source. The measurement workflow (see
  `WORKFLOW.md` M5) reads these; it does not add new fields.
- **Failures must be loud.** A scheduled scout that returns zero rows looks
  identical to a healthy source with nothing new. An error workflow must
  alert on failed executions (email in V1) so a dead source pull surfaces
  as a failed execution with a reason, not a silent empty success. A
  silently wedged scout is what makes the <24h target fail without anyone
  noticing.

## 10. Open decisions

- **LLM provider**: PRD §10 defers Claude API vs a free-tier model until
  the first 100 items are reviewed. Until then, the classify and triage
  workflows run with whichever provider a key exists for; the prompt files
  are provider-agnostic by design.
- **Final source list**: PRD §10 and the §6 pre-build gate. Scouting is
  not built until `sources/sources.yaml` is finalized and each source has a
  rationale.
- **Source-specific API keys**: resolution follows the finalized source
  list.
- **Digest notification channel (V1.5)**: Slack vs Telegram is deferred by
  PRD §7. Operational alerting (email on failed executions, design §9) is
  in scope and uses whatever email the n8n environment already has.