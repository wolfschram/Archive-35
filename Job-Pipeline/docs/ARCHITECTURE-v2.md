# Job Pipeline v2 — Full Automation Architecture

> **Status:** Planning Phase (March 2026)
> **Author:** Wolf + Claude (collaborative architecture session)
> **Scope:** Evolve Job Pipeline from semi-manual tracking into fully automated job search and application system

---

## Vision

Press "Start Search" on the Command Center → Chrome extension searches LinkedIn → results scored → Wolf approves → system creates folders, generates cover letters, fills out applications, uploads resume, and pauses for final human approval before submitting.

**Key Principle:** Full automation with human-in-the-loop at two critical points:
1. Job approval (which jobs to apply for)
2. Final submit (confirm before sending application)

Everything else is automated.

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     COMMAND CENTER (Dashboard v2)                        │
│  localhost:3000 — Express + WebSocket                                   │
│                                                                         │
│  TABS:                                                                  │
│  ┌──────────┐┌──────────┐┌──────────┐┌──────────┐┌──────────┐┌───────┐│
│  │ Pipeline ││ Personal ││ Research ││Challenges││ Applied  ││Feedback││
│  │ (exists) ││   Info   ││  Prompt  ││          ││ Folders  ││       ││
│  └──────────┘└──────────┘└──────────┘└──────────┘└──────────┘└───────┘│
│                                                                         │
│  CONTROLS:                                                              │
│  [Start Search] [Add Job URL] [ACTION NEEDED - blinking red]            │
│                                                                         │
│  INDICATORS:                                                            │
│  Coworker: FREE/BUSY | Next Search: 2h 41m | Active Applications: 3    │
└───────────┬─────────────────────────────────────┬───────────────────────┘
            │ WebSocket                           │ REST API
            ▼                                     ▼
┌───────────────────────┐              ┌───────────────────────┐
│  CONDUCTOR            │              │  Chrome Bridge         │
│  (conductor.js)       │              │  Extension             │
│  Separate Node.js     │◄────────────▶│  (Manifest V3)         │
│  process              │   REST API   │                        │
│                       │              │  Purpose: ONLY file    │
│  - State machine      │              │  drop-off bridge +     │
│  - Job queue          │              │  prompt loading        │
│  - Scheduler (cron)   │              │                        │
│  - Coordinates all    │              │  Web interaction done   │
│    agents             │              │  by Claude browser ext  │
└───┬───┬───┬───┬───────┘              └───────────────────────┘
    │   │   │   │
    │   │   │   └──────────────────────────────┐
    │   │   │                                  │
    │   │   ▼                                  ▼
    │   │ ┌─────────────────┐    ┌──────────────────────────┐
    │   │ │ Cover Letter    │    │ Application Bot           │
    │   │ │ Generator       │    │ (Playwright)              │
    │   │ │ (Claude API +   │    │                           │
    │   │ │  hallucination  │    │ - Navigate to job page    │
    │   │ │  filter)        │    │ - Create accounts         │
    │   │ │                 │    │ - Fill forms               │
    │   │ └────────┬────────┘    │ - Upload resume/CL        │
    │   │          │             │ - Detect CAPTCHA → alert   │
    │   │          ▼             │ - Pause before submit      │
    │   │ ┌─────────────────┐    └──────────┬───────────────┘
    │   │ │ Folder Builder  │               │
    │   │ │                 │               │
    │   │ │ Job-Pipeline/   │               ▼
    │   │ │   applied/      │    ┌──────────────────────────┐
    │   │ │     {company}/  │    │ Gmail MCP Server          │
    │   │ │       resume    │    │                           │
    │   │ │       cover.md  │    │ - Read verification emails│
    │   │ │       job.url   │    │ - Extract codes/links     │
    │   │ └─────────────────┘    │ - Monitor recruiter replies│
    │   │                        │ - NEVER send emails        │
    │   ▼                        └──────────────────────────┘
    │ ┌─────────────────┐
    │ │ Job Scorer      │
    │ │ (exists)        │
    │ └─────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  MULTI-PLATFORM SEARCH                                                  │
│                                                                         │
│  LinkedIn ─── Claude browser extension (visual, human-like)             │
│  Indeed ───── API if available, else Claude browser extension            │
│  Glassdoor ── Claude browser extension                                  │
│  Korn Ferry ─ Claude browser extension (job alerts + portal)            │
│  Heidrick ─── Claude browser extension                                  │
│                                                                         │
│  Results → Chrome Bridge Extension → Express API → SQLite               │
│                                                                         │
│  DEDUPLICATION: fuzzy match on company + title + URL normalization       │
│  EXCLUSION LIST: attached to search prompt, updated after each cycle    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Component 1: Command Center Dashboard v2

**File:** `PIPELINE_DASHBOARD.html` (extend existing)

### New Tabs

#### Tab: Personal Info
- Form with all application data Wolf fills out once
- Fields grouped by category:
  - **Identity:** Full name, email, phone, address, LinkedIn URL, portfolio URL (archive-35.com)
  - **Auth:** Default password for job site account creation
  - **Work Authorization:** US authorized (Yes), sponsorship required (No)
  - **Salary:** Target range ($230K-$350K), default answer strategy (just under max posted)
  - **EEO/Voluntary:** Gender, race/ethnicity, veteran status (No), disability status
  - **Availability:** Earliest start date, willing to relocate (No)
  - **Experience:** Years of experience (25+), highest education
  - **Standard Answers:** How did you hear about us, references, certifications
- Data stored in `personal_info` table in SQLite
- Loaded by Application Bot when filling forms

#### Tab: Research Prompt
- Editable search prompt configuration
- Categories with importance grades (must-have, nice-to-have, exclude)
- Do's and Don'ts for search criteria
- Exclusion list (auto-populated from jobs already in pipeline)
- Platform-specific search parameters
- Prompt preview showing exactly what gets loaded into Claude browser extension

#### Tab: Challenges
- List of all active blockers/issues
- Each challenge has: description, severity, link to relevant page, suggested action
- Manual takeover button ("I'll handle this") + hand-back button ("Resume automation")
- Holding pattern indicator (which jobs are blocked and why)
- History of resolved challenges

#### Tab: Applied Folders
- File browser view of `Job-Pipeline/applied/{company-title}/` structure
- Shows: resume (present/missing), cover letter (present/missing), job URL, application status
- Quick links to open folder, view cover letter, visit job posting

#### Tab: Feedback
- Text area for Wolf to note workflow issues during downtime
- Categorized: Bug, Improvement, Question, Observation
- Conductor processes these during idle periods
- History of feedback + resolution status

### New Controls

- **Start Search button** — Sets flag in database, Chrome Bridge extension polls for it and triggers search
- **Add Job URL input** — Paste any job posting URL, system creates NEW job entry and begins processing
- **ACTION NEEDED indicator** — Red blinking tally light (CSS animation), appears when any agent needs human input
- **Coworker Status** — Shows FREE/BUSY based on conductor's knowledge
- **Next Search Timer** — Countdown to next scheduled search cycle

### Notification System
- WebSocket connection for instant dashboard updates
- Browser Notification API for OS-level alerts (even when tab is in background)
- Centralized "Action Needed" panel listing all pending human actions with direct links

---

## Component 2: Chrome Bridge Extension (Manifest V3)

**Purpose:** Minimal custom Chrome extension that does TWO things:
1. Receives job data from Claude browser extension and forwards it to Express API
2. Loads search prompts from the Command Center into Claude browser extension

**Architecture:**
- `manifest.json` — Manifest V3, permissions: `activeTab`, `storage`, host permission for `localhost:3000`
- `background.js` (service worker) — Listens for messages from content script, forwards to Express API via fetch
- `content.js` — Injected into job platform pages, provides bridge between page and background worker
- `popup.html` — Simple status display: connection status to server, last sync time, queue count

**Communication Flow:**
```
Claude browser ext → interacts with LinkedIn/Indeed page
  → Chrome Bridge content script detects job data on page
  → Sends to background.js via chrome.runtime.sendMessage
  → background.js POSTs to localhost:3000/api/jobs
  → Express server writes to SQLite + creates date folder JSON archive
```

**Why not Native Messaging:** Localhost API calls via fetch are simpler, more reliable, and sufficient for our use case. The Express server handles file writing.

**Prompt Loading Flow:**
```
Dashboard "Start Search" button → sets search_active flag in DB
  → Chrome Bridge extension polls /api/search/status every 10s
  → When active: fetches /api/search/prompt (includes exclusion list)
  → Extension displays prompt overlay or injects into Claude browser extension context
```

---

## Component 3: Conductor (conductor.js)

**Purpose:** Persistent Node.js process that orchestrates the entire pipeline.

**Technology:**
- `better-queue` with SQLite backend — Job queue for sequencing tasks (no Redis needed)
- `node-cron` — Scheduling search cycles (every 3 hours)
- State machine — Each job follows defined workflow states

**Key Responsibilities:**
1. **Search Scheduling** — Triggers search every 3 hours via flag in DB
2. **Auto-scoring** — Runs job-scorer.js on new entries automatically
3. **Approval Queue** — Presents scored jobs to Wolf via dashboard notification
4. **Workflow Sequencing** — After approval: create folder → generate cover letter → start application
5. **Application Management** — One application at a time, sequential processing
6. **Conflict Prevention** — Manages database write coordination for concurrent Claude instances
7. **Deduplication** — Checks new jobs against existing entries (fuzzy company+title match + URL)
8. **Exclusion List Maintenance** — Updates the search prompt's exclusion list after each cycle
9. **Downtime Management** — During 3-hour gaps, processes application queue and analyzes feedback
10. **Coworker Awareness** — Tracks if coworker is needed and signals dashboard when blocked

### State Machine

```
NEW ──[auto]──▶ SCORED ──[human approval]──▶ APPROVED
  │                                              │
  │                                         [auto: create folder]
  │                                              │
  │                                    FOLDER_CREATED
  │                                              │
  │                                    [auto: generate cover letter via Claude API]
  │                                              │
  │                                    COVER_LETTER_READY
  │                                              │
  │                                    [auto: start application via Playwright]
  │                                              │
  │                                    APPLICATION_IN_PROGRESS
  │                                         │          │
  │                                    [success]   [blocked]
  │                                         │          │
  │                                    AWAITING_      CHALLENGE
  │                                    FINAL_         (human needed)
  │                                    APPROVAL            │
  │                                         │         [human resolves]
  │                                    [human click]       │
  │                                         │         back to
  │                                    SUBMITTED      APPLICATION_IN_PROGRESS
  │
  └──[human reject]──▶ REJECTED (with reason, added to exclusion list)
```

---

## Component 4: Application Bot (Playwright)

**Purpose:** Automates the browser-based job application process.

**Technology:** Playwright (better cross-browser support and auto-waiting than Puppeteer)

**Capabilities:**
1. Navigate to application URL from job posting
2. Detect if account creation is needed (looks for "Sign Up" / "Create Account" patterns)
3. Create accounts using Personal Info data (email, password)
4. Handle email verification — triggers Gmail MCP to check inbox, extract code, feed back
5. Fill forms — maps Personal Info fields to form inputs using label matching and heuristics
6. Handle multi-page flows — detects "Next" / "Continue" buttons, fills each page
7. Upload files — resume PDF and cover letter via `input[type="file"]` manipulation
8. Detect CAPTCHAs — when detected, triggers ACTION NEEDED alert for human intervention
9. Pause before submit — on the final page, triggers blinking tally light, waits for human approval
10. Screenshot on error — captures screenshots of failures for the Challenges tab

### Form Field Matching Strategy
1. Match by `<label>` text content
2. Match by `placeholder` attribute
3. Match by `name`/`id` attribute patterns (e.g., `first_name`, `lastName`, `email`)
4. Match by surrounding text content
5. Fallback: flag as Challenge for human review

### Visibility
- Runs in **headed mode** (visible browser) so Wolf can see what's happening
- Separate Chrome profile to avoid interfering with personal browsing
- Wolf can take over manually at any point (Challenge → manual takeover)

---

## Component 5: Gmail MCP Server (gmail-mcp-server.js)

**Purpose:** Dedicated MCP server for reading Wolf's Gmail

**Use Cases:**
1. Email verification codes during account creation
2. Monitoring for recruiter responses (read-only alerting)

**MCP Tools:**
- `check_verification_email` — Searches recent inbox for verification emails, extracts code/link
- `check_recruiter_responses` — Searches for replies from companies in the pipeline
- `list_job_related_emails` — Lists emails matching company names in the pipeline

**Constraints:**
- **NEVER sends emails** — Read-only access
- Uses Gmail API with OAuth2 (Wolf's personal Gmail)
- Filters only job-related emails to avoid touching personal mail

---

## Component 6: Folder Structure Automation

**Trigger:** Job status changes to APPROVED

**Creates:**
```
Job-Pipeline/
├── scraped/
│   └── 2026-03-05/
│       ├── spotify-vp-engineering.json
│       └── netflix-director-platform.json
├── applied/
│   └── spotify-vp-engineering/
│       ├── resume.pdf            (copied from master)
│       ├── cover-letter.md       (generated by Claude API)
│       ├── job-posting.url       (shortcut/link file)
│       ├── job-details.json      (full job data snapshot)
│       └── application-log.md    (timeline of what happened)
├── resume/
│   └── wolf-resume-master.pdf    (single master resume)
```

---

## Component 7: Search Prompt System

**Stored in:** `Job-Pipeline/prompts/search-prompt.md` (editable via Research Prompt tab)

**Template:**
```markdown
# Job Search Instructions

## Target Profile
- VP Engineering, COO, Head of Engineering, SVP Engineering
- Companies valuing servant leadership and people development
- Salary range: $230K-$350K base
- Location: Los Angeles, Remote, Hybrid (West Coast preferred)

## Must-Have Criteria
- Senior leadership role (VP+)
- People management component (50+ engineers)
- Transformation or culture-building mandate

## Nice-to-Have
- Media/broadcast/streaming industry
- Post-merger integration
- International scope

## Exclude
- Individual contributor roles
- Hands-on coding required
- Startups under 50 people
- Contract/consulting roles

## ALREADY IN PIPELINE (do not surface these):
- Spotify — VP of Engineering, Platform
- Netflix — Director of Engineering, Studio Tech
- [auto-updated list from database]

## Search Behavior
- Find 5-10 quality matches per session
- Prioritize new postings (last 7 days)
- Include the job URL for each result
- For each match, provide: Company, Title, URL, Why it's a fit (1 sentence)
```

---

## Component 8: Deduplication Engine

**Runs:** Every time a new job is added to the pipeline

**Strategy:**
1. **Exact URL match** — Normalize URLs (strip tracking params, canonicalize)
2. **Fuzzy company+title match** — Levenshtein distance < 3 on normalized strings (using Fuse.js)
3. **Cross-platform detection** — Same job posted on LinkedIn AND Indeed has different URLs but same company+title
4. **Result:** If duplicate detected, merge sources (note both platforms) and skip re-adding

---

## Component 9: Hallucination Filter

**Purpose:** Verify generated cover letters don't contain fabricated claims

**Process:**
- After cover letter generation via Claude API, run a verification pass
- Check all factual claims against Wolf's context files:
  - Years of experience mentioned matches (25+)
  - Company names mentioned are real companies Wolf worked at
  - Numbers cited (250 engineers, etc.) match documented facts
  - No technologies/skills claimed that aren't in Wolf's background
- Flag any mismatches in the cover letter before saving

**Source of Truth:**
- `archive35-context-folder/CONTEXT.md`
- `archive35-context-folder/career-narrative.md`
- `Job-Pipeline/prompts/cover-letter-template.md`

---

## Component 10: Auto-Start System

**Technology:** pm2 (Node.js process manager) + macOS launchd

**Processes managed:**
1. `server.js` — Express API + Dashboard (port 3000)
2. `conductor.js` — Orchestration engine
3. `gmail-mcp-server.js` — Gmail integration (MCP stdio, started by Claude)

**Setup:**
```bash
pm2 start server.js --name "pipeline-server"
pm2 start conductor.js --name "pipeline-conductor"
pm2 save
pm2 startup  # generates launchd plist for macOS auto-start on reboot
```

---

## Multi-Platform Search Strategy

| Platform | Method | API Available? | Notes |
|----------|--------|---------------|-------|
| LinkedIn | Claude browser extension | No public API | Must use visual browsing, human-like pacing |
| Indeed | API if available, else browser ext | Limited/deprecated | Research needed on current API status |
| Glassdoor | Claude browser extension | No public API | Requires login |
| ZipRecruiter | Claude browser extension | Partner API only | Visual browsing |
| Wellfound | Claude browser extension | Limited API | Startup-focused |
| Korn Ferry | Claude browser extension | No API | Executive recruiter portal |
| Heidrick & Struggles | Claude browser extension | No API | Executive recruiter portal |

**Sequencing:**
1. LinkedIn first (primary source, most VP+ roles)
2. Submit LinkedIn results to pipeline before moving to next platform
3. Indeed second
4. Glassdoor third
5. Executive recruiters last (lower volume, higher quality)
6. Each platform search separated by brief pause
7. Full cycle takes ~30-45 minutes
8. 3-hour cooldown before next cycle

---

## Related Documentation

- [Database Schema](./DATABASE-SCHEMA-v2.md) — Full schema with all new tables
- [API Reference](./API-REFERENCE-v2.md) — All endpoints (existing + new)
- [Planning Decisions](./PLANNING-DECISIONS.md) — Complete Q&A log from planning sessions
- [Build Sequence](./BUILD-SEQUENCE.md) — Phase 7-13 implementation order
- [Requirements](./REQUIREMENTS.md) — All captured requirements organized by workstream
