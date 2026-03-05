# Job Pipeline v2 — Build Sequence

> Phases 7-13 extend the existing Phase 1-6 foundation
> Each phase builds on the previous one

---

## Phase 7: Foundation (Command Center v2 + Infrastructure)

**Goal:** Extend the dashboard and server to support all new functionality

1. Database schema migration — add new tables (personal_info, challenges, search_history, notifications, feedback, exclusion_list)
2. New API endpoints — personal info, challenges, notifications, feedback, search control, applied folders
3. WebSocket integration into Express server (ws library)
4. Dashboard v2 — add tab navigation system
5. Personal Info tab — form with all application fields, saves to DB
6. Research Prompt tab — editable search prompt configuration with exclusion list
7. Challenges tab — active blockers list, manual takeover/handback buttons
8. Applied Folders tab — file browser for applied/{company}/ structure
9. Feedback tab — submit and view workflow observations
10. Blinking ACTION NEEDED indicator (CSS animation + WebSocket trigger)
11. Add Job URL input — paste URL, creates NEW job entry
12. Coworker status indicator (FREE/BUSY)
13. Next Search Timer countdown
14. Browser Notification API integration (OS-level alerts)
15. pm2 configuration (ecosystem.config.js) + auto-start setup

**Verification:**
- [ ] `npm run migrate` — new tables created successfully
- [ ] Dashboard loads with all 6 tabs
- [ ] Personal Info form saves and retrieves data
- [ ] WebSocket connection established (check browser console)
- [ ] Blinking indicator appears when notification created via API
- [ ] "Add Job URL" creates new job entry
- [ ] pm2 starts server + conductor, survives reboot

---

## Phase 8: Chrome Bridge Extension

**Goal:** Build the minimal Chrome extension that bridges Claude browser extension with the local pipeline

1. Manifest V3 setup (manifest.json with permissions)
2. Background service worker — API communication with localhost:3000
3. Content script — page data extraction on job platform pages
4. Popup UI — connection status, last sync, queue count
5. Prompt loading from Command Center (/api/search/prompt)
6. Search flag polling (/api/search/status every 10s)
7. Test with Express server — verify POST /api/jobs works from extension

**Verification:**
- [ ] Extension loads in Chrome (chrome://extensions, developer mode)
- [ ] Popup shows "Connected to Pipeline Server"
- [ ] Extension successfully POSTs test job data to API
- [ ] Start Search flag triggers extension to fetch prompt
- [ ] Extension works alongside Claude browser extension without conflicts

---

## Phase 9: Conductor

**Goal:** Build the orchestration engine that coordinates all pipeline activity

1. conductor.js process setup (standalone Node.js)
2. State machine implementation for job workflow (NEW → SCORED → APPROVED → ... → SUBMITTED)
3. Job queue (better-queue with SQLite backend)
4. Scheduler (node-cron for 3-hour search cycles)
5. Deduplication engine (Fuse.js for fuzzy matching + URL normalization)
6. Exclusion list auto-maintenance (update after each cycle)
7. Notification dispatch (create entries + emit WebSocket events)
8. Coworker awareness tracking
9. Integration with existing job-scorer.js (auto-score new entries)
10. Cover letter generation via Claude API (Anthropic SDK)
11. Hallucination filter (verify cover letter claims against context files)
12. Folder structure automation (create applied/{company}/ on approval)

**Verification:**
- [ ] Conductor auto-scores new jobs within 30 seconds of addition
- [ ] Approved job triggers: folder creation → cover letter generation → hallucination check
- [ ] Deduplication prevents same job from being added twice
- [ ] 3-hour schedule triggers search flag at correct intervals
- [ ] Notifications appear in dashboard in real-time via WebSocket
- [ ] Cover letter passes hallucination filter (no fabricated claims)
- [ ] Folder contains: resume.pdf, cover-letter.md, job-details.json, job-posting.url

---

## Phase 10: Application Bot

**Goal:** Automate the browser-based job application process

1. Playwright setup and Chrome profile management
2. Form field detection engine (label matching, placeholder, name/id patterns)
3. Form filling logic (maps personal_info table → form fields)
4. Multi-page flow navigation (detect "Next"/"Continue" buttons)
5. File upload handler (resume PDF + cover letter via input[type="file"])
6. Account creation flow (detect sign-up pages, fill with default credentials)
7. CAPTCHA detection → Challenge creation → ACTION NEEDED notification
8. Pre-submit pause → blinking tally light → wait for human approval
9. Screenshot on error → save to challenges
10. Application log writing (timeline entries to applied/{company}/application-log.md)

**Verification:**
- [ ] Playwright opens visible browser, navigates to test URL
- [ ] Form filling correctly maps personal info to common field patterns
- [ ] File upload works for resume PDF
- [ ] Multi-page navigation detects and clicks "Next" buttons
- [ ] CAPTCHA detection triggers ACTION NEEDED alert in dashboard
- [ ] Pre-submit pause works (system waits for human approval)
- [ ] Wolf can take over manually (MANUAL_TAKEOVER) and hand back

---

## Phase 11: Gmail MCP Server

**Goal:** Enable automated email verification code extraction

1. Gmail API OAuth2 setup (Google Cloud project, credentials)
2. MCP server implementation (stdio transport, same pattern as mcp-server.js)
3. Verification email detection (search recent inbox by sender/subject patterns)
4. Code/link extraction (regex patterns for common verification formats)
5. Recruiter response monitoring (alert when companies reply)
6. Integration with Application Bot (feed verification codes back to form filling)

**Verification:**
- [ ] Gmail MCP server starts and responds to MCP protocol
- [ ] Can read recent emails from inbox
- [ ] Verification code extraction works on test verification email
- [ ] Code feeds back to Application Bot, enabling continued form filling
- [ ] Recruiter response detection creates notification in dashboard

---

## Phase 12: Search Prompt + Multi-Platform

**Goal:** Enable multi-platform job search with configurable prompts

1. Search prompt template system (prompts/search-prompt.md)
2. Research Prompt tab editor in Command Center (WYSIWYG-like editing)
3. LinkedIn search flow via Claude browser extension
4. Indeed integration (API if available, else browser extension)
5. Glassdoor integration (browser extension)
6. Executive recruiter portal integration (Korn Ferry, Heidrick & Struggles)
7. Platform-specific result parsing (normalize data across platforms)
8. Cross-platform deduplication (same job on LinkedIn + Indeed = one entry)
9. Search sequencing (LinkedIn → Indeed → Glassdoor → executive, with brief pauses)

**Verification:**
- [ ] Full search cycle: Start → LinkedIn search → results in pipeline → auto-scored → notification sent
- [ ] Multi-platform: LinkedIn + Indeed results both appear, duplicates merged
- [ ] Exclusion list prevents re-finding already-pipelined jobs
- [ ] Search prompt correctly includes current exclusion list
- [ ] Search history logged with platform, jobs found, jobs added

---

## Phase 13: Polish + Integration Testing

**Goal:** End-to-end reliability and error recovery

1. End-to-end testing of full workflow (search → score → approve → apply → submit)
2. Error handling for every failure mode (network errors, site changes, timeouts)
3. Recovery logic (resume interrupted applications, retry failed steps)
4. Performance optimization (connection pooling, caching)
5. Edge case handling (job posting removed, form layout changed, account already exists)
6. Dashboard UX polish (loading states, error feedback, responsive design)
7. Documentation finalization

**End-to-End Verification:**
- [ ] Press "Start Search" → search runs → 5 jobs appear → auto-scored
- [ ] Approve 1 job → folder created → cover letter generated → hallucination check passes
- [ ] Application starts → account created if needed → forms filled → files uploaded
- [ ] Pre-submit pause → blinking indicator appears → Wolf clicks approve
- [ ] Application submitted → status updated → folder complete with all artifacts
- [ ] 3-hour timer starts → next search cycle triggers automatically

---

## File Creation Summary

### New Files
```
Job-Pipeline/
├── conductor.js                    # Orchestrator process
├── application-bot.js              # Playwright automation
├── gmail-mcp-server.js             # Gmail read-only MCP
├── dedup-engine.js                 # Deduplication logic
├── hallucination-filter.js         # Cover letter verification
├── migrate-db.js                   # Schema migration for new tables
├── ecosystem.config.js             # pm2 configuration
├── prompts/
│   └── search-prompt.md            # Search prompt template
├── chrome-bridge-extension/
│   ├── manifest.json
│   ├── background.js
│   ├── content.js
│   ├── popup.html
│   └── popup.js
├── applied/                        # Auto-created per approved job
├── scraped/                        # JSON archive by date
├── resume/
│   └── wolf-resume-master.pdf      # Placed by Wolf
└── docs/                           # This documentation
```

### Modified Files
```
Job-Pipeline/
├── server.js                       # New endpoints, WebSocket, static serving
├── init-db.js                      # Reference (migration uses migrate-db.js)
├── PIPELINE_DASHBOARD.html         # Complete overhaul — tabs, controls, notifications
├── package.json                    # New dependencies
├── mcp-server.js                   # New MCP tools for conductor
└── job-scorer.js                   # Auto-trigger integration with conductor
```

### New Dependencies
```json
{
  "playwright": "^1.40.0",
  "ws": "^8.16.0",
  "node-cron": "^3.0.3",
  "better-queue": "^3.8.12",
  "fuse.js": "^7.0.0",
  "pm2": "^5.3.0",
  "googleapis": "^130.0.0",
  "@anthropic-ai/sdk": "^0.30.0"
}
```
