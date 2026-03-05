# Job Pipeline v2 — API Reference

> Base URL: `http://localhost:3000`
> Transport: REST (JSON) + WebSocket

---

## Existing Endpoints (Phase 1-6)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Serves dashboard HTML |
| GET | `/api/stats` | Pipeline statistics (total, by status, conversion rate) |
| GET | `/api/jobs` | List jobs. Query: `?status=SCORED&sort=score` |
| GET | `/api/jobs/:id` | Single job detail |
| POST | `/api/jobs` | Add new job. Body: `{company, title, description?, source?, url?, notes?}` |
| PUT | `/api/jobs/:id` | Update job fields (status, score, notes, cover_letter, template_version) |
| GET | `/api/agents` | List all agents with status |
| GET | `/api/errors` | Recent errors (last 50) |
| GET | `/api/template-metrics` | Feedback Analyzer: conversion rates by template version |
| GET | `/api/prompt/:id` | Generate formatted P→P→R cover letter prompt for a job |
| GET | `/api/cover-letter-template` | Raw cover letter template markdown |

---

## New Endpoints (Phase 7+)

### Search Control

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/search/status` | Current search state: `{active, platform, nextScheduled, prompt}` |
| POST | `/api/search/start` | Trigger immediate search cycle. Sets `search_active` flag. |
| GET | `/api/search/prompt` | Formatted search prompt with current exclusion list |
| GET | `/api/search/history` | List of past search cycles with stats |

**POST /api/search/start Response:**
```json
{
  "status": "started",
  "platforms": ["linkedin", "indeed", "glassdoor"],
  "nextScheduled": "2026-03-05T18:00:00Z"
}
```

### Personal Info

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/personal-info` | Returns personal info (single row) |
| PUT | `/api/personal-info` | Upsert personal info form data |

**PUT /api/personal-info Body:**
```json
{
  "full_name": "Wolf Schram",
  "email": "wolf@example.com",
  "phone": "+1-555-0123",
  "linkedin_url": "https://linkedin.com/in/wolfschram",
  "us_authorized": "Yes",
  "veteran_status": "No",
  "salary_strategy": "near_max"
}
```

### Challenges

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/challenges` | List active challenges. Query: `?status=ACTIVE` |
| POST | `/api/challenges` | Log new challenge. Body: `{job_id, type, description, url?}` |
| PUT | `/api/challenges/:id` | Update challenge: resolve, manual takeover, etc. |

**Challenge Types:** `CAPTCHA`, `ACCOUNT_CREATION`, `VERIFICATION`, `FORM_ERROR`, `UPLOAD_FAILED`, `OTHER`

**PUT /api/challenges/:id Body (manual takeover):**
```json
{
  "status": "MANUAL_TAKEOVER"
}
```

**PUT /api/challenges/:id Body (resolve):**
```json
{
  "status": "RESOLVED",
  "resolved_at": "2026-03-05T14:30:00Z"
}
```

### Notifications

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/notifications` | Unread notifications |
| GET | `/api/notifications/count` | `{count: 3}` — for blinking indicator |
| PUT | `/api/notifications/:id/read` | Mark notification as read |

**Notification Types:** `APPROVAL_NEEDED`, `CHALLENGE`, `SEARCH_COMPLETE`, `APPLICATION_READY`, `COWORKER_NEEDED`, `FEEDBACK_RESPONSE`

### Feedback

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/feedback` | All feedback entries. Query: `?status=NEW` |
| POST | `/api/feedback` | Submit new feedback. Body: `{category, content}` |
| PUT | `/api/feedback/:id` | Update status/resolution |

**Feedback Categories:** `BUG`, `IMPROVEMENT`, `QUESTION`, `OBSERVATION`

### Applied Folders

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/applied` | List all applied job folders with file inventory |
| GET | `/api/applied/:folder` | Contents of a specific applied folder |

**GET /api/applied Response:**
```json
[
  {
    "folder": "spotify-vp-engineering",
    "job_id": 1,
    "company": "Spotify",
    "title": "VP of Engineering, Platform",
    "files": {
      "resume": true,
      "cover_letter": true,
      "job_details": true,
      "application_log": true
    },
    "status": "SUBMITTED"
  }
]
```

### Job from URL

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/jobs/from-url` | Add job by pasting URL. Triggers scraping + scoring. Body: `{url}` |

---

## WebSocket Events

Connect to: `ws://localhost:3000`

### Server → Client Events

| Event | Payload | Trigger |
|-------|---------|---------|
| `job:new` | `{id, company, title, source}` | New job added to pipeline |
| `job:scored` | `{id, company, title, score}` | Job scoring complete |
| `job:approved` | `{id, company, title}` | Job approved for application |
| `job:status_changed` | `{id, status, application_status}` | Any job status change |
| `notification:new` | `{id, type, message, link?}` | New notification created |
| `challenge:new` | `{id, type, description, url?}` | Challenge detected (triggers blinking) |
| `search:started` | `{platform, timestamp}` | Search cycle began |
| `search:completed` | `{platform, jobs_found, jobs_added}` | Search cycle finished |
| `application:progress` | `{job_id, step, details}` | Application step completed |
| `application:blocked` | `{job_id, challenge_id, reason}` | Application needs human help |
| `coworker:status` | `{status: 'FREE'/'BUSY'}` | Coworker availability changed |

### Client → Server Events

| Event | Payload | Purpose |
|-------|---------|---------|
| `job:approve` | `{id}` | Approve job for application |
| `job:reject` | `{id, reason}` | Reject job with reason |
| `application:approve_submit` | `{job_id}` | Approve final application submission |
| `challenge:takeover` | `{challenge_id}` | Wolf taking manual control |
| `challenge:handback` | `{challenge_id}` | Wolf handing back to automation |

---

## MCP Server Tools (Existing + New)

### Existing (mcp-server.js)
- `pipeline_stats` — Pipeline statistics
- `list_jobs` — List/filter jobs
- `get_job` — Job detail by ID
- `add_job` — Add new job
- `update_job` — Update job fields
- `log_outcome` — Log interview/rejection
- `template_metrics` — Feedback Analyzer report
- `generate_cover_letter_prompt` — P→P→R prompt for a job
- `search_qa_bank` — Interview Q&A lookup

### New (to be added)
- `approve_job` — Approve job for application (triggers full workflow)
- `reject_job` — Reject job with reason
- `get_challenges` — List active challenges
- `resolve_challenge` — Mark challenge resolved
- `search_status` — Current search state
- `start_search` — Trigger search cycle
- `coworker_status` — Report coworker availability

### Gmail MCP Server (gmail-mcp-server.js)
- `check_verification_email` — Find and extract verification codes
- `check_recruiter_responses` — Monitor for company replies
- `list_job_related_emails` — List emails matching pipeline companies
