# PRD: Opportunity Radar (working title)

## 1. Problem
Staying on top of new tech, trends, and money-making opportunities (gigs, arbitrage, tools) takes constant manual scanning. There's no system turning raw signals into decision-ready options.

## 2. Goal
Build a bot pipeline that scouts sources continuously, a triage bot that organizes findings into structured, actionable options, and a review step where the human approves before any further action (drafting pitches, scaffolding repos, etc.) is taken.

**V1 goal:** works for you personally.
**V2 goal:** reusable/configurable so others can spin up their own instance (different sources, different niches).

## 3. Non-Goals (V1)
- No auto-execution of opportunities (no auto-applying to gigs, no auto-posting).
- No multi-tenant UI yet — V1 is single-user, config-driven.
- No mobile app — web dashboard or n8n's own UI is enough initially.

## 4. Users
- **V1:** You — full-stack engineer, wants curated, decision-ready opportunity feed.
- **V2:** Any technically-inclined person who can fill in a config (sources, keywords, niches) and self-host.

## 5. System Overview
Three logical bot roles, orchestrated in n8n (self-hosted, free):

1. **Scout bots** — pull raw signals from chosen sources (news, forums, job boards, product launch sites, etc.) on a schedule.
2. **Filter/classify bot** — tags each item: trend / gig / arbitrage opportunity; scores relevance.
3. **Triage bot** — turns qualified items into a structured "opportunity card": what it is, why it matters, effort estimate, possible actions, money potential, expiry/urgency. Writes to Airtable for you to review.

You review the queue → approve an item → *only then* does Claude (or a follow-up bot) draft an implementation plan.

## 6. Core Features (V1)
| # | Feature | Description |
|---|---|---|
| 1 | Source scouting | Scheduled pulls from a defined source list (RSS, APIs, search) |
| 2 | Classification | Tag as trend/gig/arbitrage + relevance score |
| 3 | Dedup | Avoid re-surfacing the same item |
| 4 | Opportunity card generation | Structured summary + suggested next actions |
| 5 | Review queue | Single place (Airtable) to approve/reject items |
| 6 | Approval trigger | Approving an item kicks off a "draft implementation plan" step |
| 7 | Classification feedback loop | Every approve/reject action appends to a labeled dataset (item text + decision + timestamp) |

Note on **Review queue**: V1 review UI is Airtable grid + n8n execution log. A custom live dashboard is explicitly V2.

### Source Selection (Pre-Build Gate)
No n8n nodes are written until the source list is finalized and justified. Sources must be niche or edge-providing, not generic aggregators (e.g., not TechCrunch RSS or HN front page alone) — the value of this system is surfacing what a generic feed wouldn't.

### V1.5: Feedback-Informed Classification
Periodically re-inject the labeled dataset (from the feedback loop above) into the classifier prompt as few-shot examples, so classification improves from your actual approve/reject history rather than staying static. Rationale: without this loop, classification quality plateaus and the queue loses trust.

## 7. Out of scope for V1 (backlog)
- Auto-drafting pitches/proposals before approval
- Notifications (Slack/Telegram digest) — nice-to-have, V1.5
- Multi-user config UI
- Custom real-time dashboard (V1 uses Airtable + n8n UI)

## 8. Success Metrics
- Time from "signal appears online" to "shows up in your queue": target < 24h
- False-positive rate (irrelevant items surfaced) trending down over time
- False-positive rate decreases measurably month-over-month, tracked against the labeled dataset
- At least 1 surfaced opportunity per month leads to a real action taken by the user

## 9. Tech Stack
- Orchestration: **n8n**, self-hosted (Docker)
- Storage/review UI: Airtable (locked choice — its API is cleaner for n8n integration and its views are better suited to triage than Notion's document-first model)
- AI classification/summarization: Claude API (or free-tier LLM initially)
- Hosting: your own VPS or free-tier cloud (Render/Fly.io/Oracle free tier)

## 10. Open Questions
- Final list of sources per category (trend / gig / arbitrage)
- Any source-specific API keys needed
- Which LLM for classification — Claude API vs free-tier alternative — decided by cost/quality tradeoff after first 100 items

---

# What YOU need to set up externally (as we build)

These are accounts/keys only *you* can create — I can't sign up for them on your behalf.

1. **VPS or free hosting for n8n**
   - Options: Oracle Cloud Free Tier (most generous, permanent free), Render free web service, or a cheap VPS (~$3–5/mo if you skip free tiers).
   - Action: pick one, spin up Docker there.

2. **n8n instance**
   - Self-hosted via Docker — you'll need Docker installed on the host above.
   - Action: get it running and reachable (with basic auth enabled).

3. **Claude API key**
   - From console.anthropic.com — needed for classification/summarization nodes.
   - Action: create key, note usage limits/billing.

4. **Airtable account**
   - Free tier: good for structured records + views, and cleaner API for n8n than Notion.
   - Action: create account, we'll design the schema together.

5. **Source access**
   - API keys for any source you want beyond RSS (e.g. a job board API, Reddit API, Product Hunt API, NewsAPI, etc.) — depends on final source list.
   - Action: hold off until we finalize sources in the next step.

6. **(Optional, later) Notification channel**
   - Telegram bot token or Slack webhook, if you want push alerts instead of just checking the queue.

Nothing here is urgent yet except #1 and #2 — get n8n running, and we can start wiring the first scout bot.