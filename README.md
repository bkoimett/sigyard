# sigyard — Opportunity Radar

A bot pipeline that scouts niche sources continuously, turns the raw
signals into structured, decision-ready opportunity cards, and stops there:
you review and approve every card in Airtable before anything further (like
drafting a plan) happens. Built for one person, self-hosted.

## Stack

- n8n (self-hosted, Docker Compose) for orchestration
- Postgres as n8n's backing database
- Airtable for signal/card storage and the review queue
- Provider-agnostic LLM (Claude or a free-tier model) for classification
  and triage
- A single VPS

Full reasoning per layer: [`design.md`](./design.md) §1.

## Getting started

Deploy the n8n stack:

```bash
cd infra
cp n8n.env.example .env   # set ADMIN_EMAIL, ADMIN_PASSWORD, ENCRYPTION_KEY
docker compose up -d
```

Then, once in n8n's UI:

1. Create the Airtable base from `airtable/base-schema.md` (or run
   `scripts/apply-base-schema.sh`) and enter its base id per environment.
2. Enroll credentials in n8n: the `Airtable API` token, an LLM key, and
   any per-source keys listed in `sources/sources.yaml`.
3. Import the workflows from `n8n/workflows/`. Imported JSON references
   credential ids from the exporting instance, so re-select each credential
   on the imported workflows by hand once.
4. Finalize `sources/sources.yaml`.

Nothing runs before the source list is finalized; that is the pre-build
gate in [`PRD.md`](./PRD.md) §6.

## Project docs

This repo is organized around four documents. Read the one that matches
your question:

- [`PRD.md`](./PRD.md) — what this product does and why, including what's
  explicitly out of scope for now
- [`design.md`](./design.md) — architecture, schema, and the reasoning
  behind technical decisions
- [`AGENTS.md`](./AGENTS.md) — conventions and ground rules for anyone
  (human or AI) working in this repo
- [`WORKFLOW.md`](./WORKFLOW.md) — how work is branched, committed, and
  tracked through GitHub issues and milestones

## Status

Scaffolding complete: stack, schema, source gate, and folder structure are
decided. No workflows, sources, or Airtable schema are built yet. The
first real work is Milestone 1 in `WORKFLOW.md`.

## License

[MIT](./LICENSE).