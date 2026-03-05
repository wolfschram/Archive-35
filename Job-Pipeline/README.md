# Job Pipeline

A local-first job search command center built for VP/Director-level engineering leadership roles. Tracks applications, scores opportunities, generates cover letters using the **Problem→Product→Result** framework, and measures what's working.

## Quick Start

```bash
cd ~/Archive-35/Job-Pipeline
npm install
npm run init-db    # Creates pipeline.db with schema + sample data
npm start          # Dashboard at http://localhost:3000
```

## What This Does

- **Pipeline Dashboard** — Track every job from discovery → application → interview → offer
- **REST API** — Full CRUD for jobs, agents, errors, and metrics
- **Cover Letter Generator** — One-click "Copy Prompt for Cowork" builds a complete P→P→R prompt ready to paste into Claude Desktop
- **Feedback Analyzer** — Tracks which cover letter template version yields the highest interview conversion rate
- **Auto-Refresh** — Dashboard updates every 60 seconds

## Architecture

```
Browser → PIPELINE_DASHBOARD.html
              ↕ fetch() every 60s
          server.js (Express)
              ↕ better-sqlite3
          pipeline.db (SQLite)
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/stats` | Pipeline statistics |
| GET | `/api/jobs` | All jobs (`?status=SCORED&sort=score`) |
| GET | `/api/jobs/:id` | Single job detail |
| POST | `/api/jobs` | Add new job |
| PUT | `/api/jobs/:id` | Update job |
| GET | `/api/agents` | Agent statuses |
| GET | `/api/errors` | Recent errors |
| GET | `/api/template-metrics` | Conversion rates by template version |
| GET | `/api/prompt/:id` | Generate cover letter prompt for a job |

## Database Schema

**4 tables + 1 view:**
- `jobs` — Company, title, status, score, template_version
- `agents` — Automation agent tracking
- `errors` — Error log with FK to jobs and agents
- `qa_bank` — Interview Q&A pairs with template versioning
- `template_metrics` — (View) Auto-aggregated conversion rates

## Job Statuses

```
NEW → SCRAPED → SCORED → APPLIED → INTERVIEW → OFFER
                                  ↘ REJECTED
```

## The P→P→R Framework

Every cover letter follows:
1. **Problem** — What leadership/people challenge existed?
2. **Product** — How did I apply servant leadership?
3. **Result** — What people-focused outcomes occurred?

The "Copy Prompt for Cowork" button (visible on SCORED jobs) builds a complete prompt with the framework, leadership stories, and job description — ready to paste into Claude Desktop.

## Feedback Analyzer (Phase 6)

Track which opening hook converts best:

```bash
npm run analyze
```

Outputs conversion rates grouped by `template_version`. When you iterate on your P→P→R opening hook, bump the version and measure the difference.

## Files

```
Job-Pipeline/
├── package.json                 # Dependencies
├── server.js                    # Express server + REST API
├── init-db.js                   # Database schema + seed data
├── feedback-analyzer.js         # Template version analysis CLI
├── PIPELINE_DASHBOARD.html      # Single-file dashboard UI
├── LESSONS_LEARNED.md           # What's working, what's not
├── NOTES.md                     # Phase 6 design + future plans
├── README.md                    # This file
└── prompts/
    └── cover-letter-template.md # P→P→R master prompt
```

## MCP Integration (Future)

```bash
claude mcp add sqlite -- npx -y @modelcontextprotocol/server-sqlite ~/Archive-35/Job-Pipeline/pipeline.db
```

Gives Claude Desktop direct access to query and update the pipeline database.
