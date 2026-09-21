# WORKFLOW.md — Git flow, milestones, and issues

**Read this file before making any change, and again before committing or
pushing.** It defines how work is branched, committed, and closed out in
this repo. It complements `PRD.md` (what to build), `design.md`
(architecture), and `AGENTS.md` (coding conventions). This file governs
process, not code.

Milestones and issues below are meant to be created in GitHub before work
starts (Milestones tab + Issues tab), using these exact names/descriptions.
Once created, every commit and PR references the issue it belongs to.

---

## 1. Branching

- `main` is always deployable. No direct commits to `main`.
- One branch per issue, branched from `main`:
  ```
  <type>/<issue-number>-<short-slug>
  ```
  Examples: `feat/5-source-list`, `chore/3-export-scripts`.
- `<type>` matches the commit type table in §2.
- Keep a branch scoped to its issue. If work reveals a second, unrelated
  issue, open a new issue and a new branch. Don't scope-creep one branch.

## 2. Commit message format

Conventional Commits, referencing the issue number:

```
<type>(<scope>): <short summary> (#<issue-number>)
```

| type | use for |
|---|---|
| `feat` | a new feature or capability |
| `fix` | a bug fix |
| `chore` | tooling, deps, config, no behavior change |
| `docs` | documentation only (including this file, PRD, design) |
| `refactor` | change that isn't a fix or a feature |
| `test` | adding or fixing tests |
| `style` | formatting only, no logic change |

`<scope>` is the affected area: `infra`, `sources`, `prompts`, `airtable`,
`n8n`, `scripts`, `docs`, matching folder/domain names from `design.md` §6
where possible.

Rules:
- One logical change per commit. Don't bundle unrelated changes into one
  commit just because they happened in the same session.
- Every commit for an issue includes that issue's number in parentheses,
  even across multiple commits. This is what lets commits be grouped
  chronologically by issue later.
- Write the summary in the imperative mood ("add", not "added"/"adds").
- Body (optional, below the summary line) explains *why*, not *what*. The
  diff already shows what changed.

Example sequence of commits for one issue:
```
feat(sources): define source list with rationales (#5)
docs(airtable): document signals and cards schema (#6)
```

## 3. Grouping commits and writing the PR description

Before pushing a finished issue's branch, group and present its commits
chronologically, then add a PR description block directly below the group,
ready to paste into GitHub's PR description field. Use this shape:

```
## Issue #<N>: <issue title>

- feat(sources): define source list with rationales (#5)
- docs(airtable): document signals and cards schema (#6)

---
Closes #5

<one or two sentences summarizing what this PR does and any
follow-up/TODO left for a later issue.>
```

- Use **`Closes #<N>`** (not `Fixes`/`Resolves`) as the default closing
  keyword for consistency across the repo, unless the issue is explicitly
  a bug report. Then use `Fixes #<N>`. Both are recognized by GitHub to
  auto-close the issue on merge.
- If a PR addresses more than one issue (avoid this where possible; prefer
  one issue per PR), list every issue with its own closing keyword on its
  own line: `Closes #4`, `Closes #5`.
- The PR title should be the same as the issue title.

## 4. Before committing/pushing — checklist

- [ ] Branch name matches `<type>/<issue-number>-<short-slug>`.
- [ ] Every commit message follows the `<type>(<scope>): <summary> (#N)` format.
- [ ] Commits are grouped and listed chronologically for review.
- [ ] The PR description block (§3) is generated and ready to paste.
- [ ] The relevant `AGENTS.md` "Definition of done" checklist items pass
      for anything the issue touched.

---

## 5. Milestones

Create these in GitHub's Milestones tab before opening issues, then assign
each issue below to its milestone.

### Milestone 1: Project Setup & Infrastructure
The deployable unit exists: docker-compose runs n8n + Postgres behind basic
auth on a VPS, and workflow JSON can be moved between the instance and the
repo. Nothing user-facing yet.

### Milestone 2: Sources & Data Foundation
The source list is finalized (PRD §6 pre-build gate), the Airtable schema
is documented and applied, and scout workflows pull signals into Airtable
with the `Content hash` dedup boundary working.

### Milestone 3: Classification & Triage
Classify tags and scores each signal; triage turns scored signals into
opportunity cards that show up in the review queue. This is the first
milestone where the pipeline produces something the user reviews.

### Milestone 4: Review, Approval & Feedback
Review actions (approve/reject) append to the labeled dataset, approving a
card drafts an implementation plan, and the labeled data feeds back into
classification (V1.5).

### Milestone 5: Measurement, QA & Launch
Success-metric tracking from PRD §8 is wired, failed executions alert
instead of failing silently, and the first end-to-end run reaches the
production review queue.

---

## 6. Issues

> Issue numbers below match the live issues in GitHub; each milestone's
> issues are listed in ascending number order. Every commit references the
> number of the issue it belongs to.

### Milestone 1: Project Setup & Infrastructure

**#1 — Add docker-compose stack for n8n + Postgres**
`infra/docker-compose.yml` with n8n, a colocated Postgres (per `design.md`
§1), a reverse proxy, and `n8n.env.example` listing the real required vars
(basic auth credentials, encryption key, ports). No secrets in the
committed file.

**#2 — Stand up n8n with basic auth on the VPS**
Provision the VPS, run the compose stack, confirm n8n is reachable and
protected by basic auth per `design.md` §4. Confirm execution history is
enabled.

**#3 — Add workflow export/import scripts**
`scripts/export-workflows.sh` pulls the running instance's workflows into
`n8n/workflows/` as JSON, per `design.md` §6. Document the re-selecting-
credentials-by-hand caveat from `design.md` §5 in the script header.

**#4 — Enroll credentials per environment**
Airtable token, the LLM provider key, and placeholder source keys as n8n
credentials, named so the workflows can reference them by env (`design.md`
§5, §8). No key value touches the repo.

### Milestone 2: Sources & Data Foundation

**#5 — Finalize and justify the source list**
Write `sources/sources.yaml` with slug, category, type, URL, schedule, key
ref (if any), and a one-line rationale per source. This closes the PRD §6
pre-build gate; scouting is not built before this is reviewed.

**#6 — Document the Airtable base schema**
`airtable/base-schema.md` covering the `signals`, `cards`, and `labels`
tables, every field, the uniqueness constraints, and the review-queue and
labeled-dataset views from `design.md` §2.

**#7 — Create and apply the Airtable base**
Create the dev `sigyard` base and apply the schema from `design.md` §2,
including the unique-enforced `signals.Content hash` field and the
`(Content hash, Decision)` unique pair on `labels`.

**#8 — Build the scout workflow for RSS sources**
Reads `sources/sources.yaml`, pulls each RSS source on its schedule,
computes the shared `Content hash` normalization from `design.md` §3, and
inserts into `signals`.

**#9 — Build the scout workflow for API/search sources**
Same contract as #8 for sources that need a key, reading the n8n credential
referenced by the source's key ref (`design.md` §5).

**#10 — Verify the dedup boundary**
Two overlapping scout runs on the same item must yield one signal: the
second insert is rejected by Airtable and treated as "already seen," per
`design.md` §7.

### Milestone 3: Classification & Triage

**#11 — Write the classification prompt**
`prompts/classify.md`: tag a signal trend/gig/arbitrage and score
relevance, per the card fields in `design.md` §2. Provider-agnostic
wording.

**#12 — Build the classify workflow**
Fetch unscored signals from Airtable, load `prompts/classify.md`, call the
environment's LLM credential (`design.md` §5), and write back
classification + relevance score on the signal. Fails loudly on LLM error.

**#13 — Write the triage prompt**
`prompts/triage.md`: turn a scored signal into the card fields (summary,
why it matters, effort, possible actions, money potential, expiry), per
`design.md` §2 and PRD §5 role 3.

**#14 — Build the triage workflow**
Load `prompts/triage.md`, generate the card, create the record in `cards`
linked to its signal with `Status = queued`, per `design.md` §2. Confirm a
generated card appears in the review-queue view.

### Milestone 4: Review, Approval & Feedback

**#15 — Build the review-trigger workflow**
Poll `cards` for `Status` changes, per `design.md` §7. On approve or
reject, append one row to `labels` (guarded by the unique
`(Content hash, Decision)` pair) and set `Reviewed at`.

**#16 — Write the draft-plan prompt**
`prompts/draft-plan.md`: draft an implementation plan for an approved card,
provider-agnostic, per `design.md` §3.

**#17 — Build the draft-plan workflow**
Triggered by an approved card from #15. Only writes
`cards.Implementation plan` when `Status = approved` AND the plan field is
empty, so a doubled poll no-ops, per `design.md` §7.

**#18 — Build the labeled dataset for feedback**
The labeled-dataset view and an export path from `labels`, so item text +
decision + timestamp is available for the V1.5 few-shot step and the
false-positive metric (`design.md` §2, §9).

**#19 — Re-inject labeled examples into classification (V1.5)**
Extend the classify workflow to pull a recent sample from the labeled
dataset into `prompts/classify.md` as few-shot examples, per PRD §6's
V1.5 note.

### Milestone 5: Measurement, QA & Launch

**#20 — Add signal-to-queue latency measurement**
Query `cards` creation minus `signals.Fetched at` and alert when it
exceeds the <24h PRD §8 target.

**#21 — Track false-positive rate over time**
Report approve/reject ratios from `labels` by source and over time, against
the PRD §8 trend target.

**#22 — Wire an error workflow for failed executions**
A workflow that fires when a scout/classify/triage/draft-plan execution
fails, alerting via email (operational alerting only; the Slack/Telegram
digest stays V1.5 per PRD §7), per `design.md` §9.

**#23 — Production deploy and first end-to-end run**
Deploy the stack to production, point it at the production Airtable base
(`design.md` §8), run the pipeline once, and confirm a real signal reaches
the review queue with correct card fields.