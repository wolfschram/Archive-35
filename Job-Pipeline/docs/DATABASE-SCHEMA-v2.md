# Job Pipeline v2 — Database Schema

> All tables stored in `pipeline.db` (SQLite with WAL mode)

---

## Existing Tables (Phase 1-6)

### jobs
Core pipeline tracking table.

```sql
CREATE TABLE IF NOT EXISTS jobs (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  company         TEXT NOT NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  status          TEXT NOT NULL DEFAULT 'NEW'
                  CHECK(status IN ('NEW','SCRAPED','SCORED','APPLIED','INTERVIEW','REJECTED','OFFER')),
  score           INTEGER,
  source          TEXT,
  url             TEXT,
  cover_letter    TEXT,
  date_added      TEXT NOT NULL DEFAULT (datetime('now')),
  date_updated    TEXT NOT NULL DEFAULT (datetime('now')),
  notes           TEXT,
  template_version TEXT DEFAULT 'v1'
);
```

### agents
Automation agent tracking.

```sql
CREATE TABLE IF NOT EXISTS agents (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  name            TEXT NOT NULL,
  type            TEXT,
  status          TEXT NOT NULL DEFAULT 'idle'
                  CHECK(status IN ('idle','running','error')),
  last_run        TEXT,
  jobs_processed  INTEGER DEFAULT 0,
  errors          INTEGER DEFAULT 0
);
```

### errors
Error log with FK relationships.

```sql
CREATE TABLE IF NOT EXISTS errors (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id          INTEGER REFERENCES jobs(id),
  agent_id        INTEGER REFERENCES agents(id),
  error_message   TEXT NOT NULL,
  timestamp       TEXT NOT NULL DEFAULT (datetime('now')),
  resolved        INTEGER DEFAULT 0
);
```

### qa_bank
Interview question/answer pairs.

```sql
CREATE TABLE IF NOT EXISTS qa_bank (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  question        TEXT NOT NULL,
  answer          TEXT,
  category        TEXT CHECK(category IN ('behavioral','technical','cultural','leadership','situational')),
  template_version TEXT DEFAULT 'v1'
);
```

### template_metrics (VIEW)
Aggregates success rates by template version for the Feedback Analyzer.

```sql
CREATE VIEW IF NOT EXISTS template_metrics AS
SELECT
  template_version,
  COUNT(*) FILTER (WHERE status IN ('APPLIED','INTERVIEW','REJECTED','OFFER')) AS total_applied,
  COUNT(*) FILTER (WHERE status = 'INTERVIEW') AS interviews,
  COUNT(*) FILTER (WHERE status = 'OFFER') AS offers,
  COUNT(*) FILTER (WHERE status = 'REJECTED') AS rejections,
  ROUND(
    CAST(COUNT(*) FILTER (WHERE status IN ('INTERVIEW','OFFER')) AS REAL) /
    NULLIF(COUNT(*) FILTER (WHERE status IN ('APPLIED','INTERVIEW','REJECTED','OFFER')), 0) * 100,
    1
  ) AS conversion_rate
FROM jobs
GROUP BY template_version;
```

---

## New Tables (Phase 7+)

### jobs — Column Addition

```sql
ALTER TABLE jobs ADD COLUMN application_status TEXT DEFAULT NULL;
-- Values: FOLDER_CREATED, COVER_LETTER_READY, APPLICATION_IN_PROGRESS,
--         AWAITING_APPROVAL, SUBMITTED, BLOCKED
```

### personal_info
Single-row table holding Wolf's application data. Filled via Personal Info tab.

```sql
CREATE TABLE IF NOT EXISTS personal_info (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  -- Identity
  full_name TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  linkedin_url TEXT,
  portfolio_url TEXT,
  -- Account creation
  default_password TEXT,
  -- Work authorization
  us_authorized TEXT DEFAULT 'Yes',
  sponsorship_required TEXT DEFAULT 'No',
  -- Compensation
  salary_strategy TEXT DEFAULT 'near_max',  -- 'near_max', 'exact', 'range'
  salary_min TEXT,
  salary_max TEXT,
  -- EEO / Voluntary
  gender TEXT,
  race_ethnicity TEXT,
  veteran_status TEXT DEFAULT 'No',
  disability_status TEXT,
  -- Availability
  willing_to_relocate TEXT DEFAULT 'No',
  earliest_start TEXT,
  -- Experience
  years_experience TEXT DEFAULT '25+',
  highest_education TEXT,
  -- Standard answers
  how_heard_default TEXT,
  -- Overflow for additional Q&A pairs
  additional_json TEXT  -- JSON blob: [{"question": "...", "answer": "..."}, ...]
);
```

### challenges
Tracks blockers and issues requiring human intervention.

```sql
CREATE TABLE IF NOT EXISTS challenges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id INTEGER REFERENCES jobs(id),
  type TEXT CHECK(type IN ('CAPTCHA','ACCOUNT_CREATION','VERIFICATION','FORM_ERROR','UPLOAD_FAILED','OTHER')),
  description TEXT NOT NULL,
  url TEXT,
  screenshot_path TEXT,
  status TEXT DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE','MANUAL_TAKEOVER','RESOLVED')),
  created_at TEXT DEFAULT (datetime('now')),
  resolved_at TEXT
);
```

### search_history
Logs each search cycle for analytics and debugging.

```sql
CREATE TABLE IF NOT EXISTS search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  platform TEXT NOT NULL,
  search_date TEXT DEFAULT (datetime('now')),
  jobs_found INTEGER DEFAULT 0,
  jobs_added INTEGER DEFAULT 0,
  prompt_used TEXT,
  notes TEXT
);
```

### notifications
Queue for dashboard alerts and the blinking tally light.

```sql
CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT CHECK(type IN ('APPROVAL_NEEDED','CHALLENGE','SEARCH_COMPLETE','APPLICATION_READY','COWORKER_NEEDED','FEEDBACK_RESPONSE')),
  message TEXT NOT NULL,
  job_id INTEGER REFERENCES jobs(id),
  link TEXT,
  read INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);
```

### feedback
Wolf's workflow observations and improvement suggestions.

```sql
CREATE TABLE IF NOT EXISTS feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT CHECK(category IN ('BUG','IMPROVEMENT','QUESTION','OBSERVATION')),
  content TEXT NOT NULL,
  status TEXT DEFAULT 'NEW' CHECK(status IN ('NEW','IN_PROGRESS','RESOLVED')),
  resolution TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  resolved_at TEXT
);
```

### exclusion_list
Auto-maintained list of jobs to exclude from future searches.

```sql
CREATE TABLE IF NOT EXISTS exclusion_list (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  company TEXT NOT NULL,
  title TEXT NOT NULL,
  reason TEXT,  -- 'applied', 'rejected_by_wolf', 'duplicate', etc.
  source_job_id INTEGER REFERENCES jobs(id),
  added_at TEXT DEFAULT (datetime('now'))
);
```

---

## Indexes

```sql
-- Existing
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_template_version ON jobs(template_version);
CREATE INDEX IF NOT EXISTS idx_errors_timestamp ON errors(timestamp);
CREATE INDEX IF NOT EXISTS idx_qa_bank_category ON qa_bank(category);

-- New
CREATE INDEX IF NOT EXISTS idx_jobs_application_status ON jobs(application_status);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_exclusion_company_title ON exclusion_list(company, title);
CREATE INDEX IF NOT EXISTS idx_search_history_date ON search_history(search_date);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);
```

---

## Entity Relationship Summary

```
personal_info (1 row) ──── used by ────▶ Application Bot (form filling)

jobs ──┬── has many ──▶ challenges
       ├── has many ──▶ notifications
       ├── has many ──▶ errors
       └── maps to ──▶ exclusion_list (via source_job_id)

agents ──── logs to ──▶ errors

search_history ──── independent (logging only)
feedback ──── independent (Wolf's input)
```
