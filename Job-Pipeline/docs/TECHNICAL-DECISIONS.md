# Job Pipeline v2 — Technical Decisions

> Confirmed technical choices for the full automation build

---

## Confirmed Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Job Queue** | `better-queue` + SQLite | No Redis dependency. Single-user local system. 5-10 jobs per session doesn't need Bull/BullMQ complexity. |
| **Cover Letter Generation** | Claude API direct (Anthropic SDK) | Fully automated, no human involvement. Conductor calls API, hallucination filter runs after. |
| **Target Machine** | Wolf's main Mac (daily driver) | launchd + pm2 for auto-start. Playwright visible on same display. |
| **Resume** | Single PDF at `Job-Pipeline/resume/wolf-resume-master.pdf` | Copied into each `applied/{job}/` folder. Tailoring happens in cover letter only. |
| **Browser Automation** | Playwright (headed mode) | Better than Puppeteer for cross-browser support and auto-waiting. Visible so Wolf can see what's happening. |
| **Chrome Bridge** | localhost fetch calls to Express API | Simpler than Native Messaging. Server handles file writing. Extension is minimal. |
| **Web Interaction** | Claude browser extension (official) | Already installed and proven. Handles intelligent browsing. Custom extension only for file bridge. |
| **Notifications** | WebSocket + Browser Notification API | Instant dashboard updates + OS-level alerts when tab is in background. |
| **Password Storage** | Plaintext in SQLite | Wolf's preference. Job site credentials are not sensitive. Simple and functional. |
| **Gmail** | Personal account, read-only | Verification codes + recruiter response monitoring. NEVER sends emails. OAuth2 via Google Cloud. |
| **Database** | SQLite with WAL mode | Sufficient for concurrent access at this volume. No need for PostgreSQL. |
| **Process Management** | pm2 | Auto-restart, startup scripts for macOS, manages server + conductor. |
| **Scheduling** | node-cron | 3-hour intervals for search cycles. Simple, no external dependency. |
| **Deduplication** | Fuse.js (fuzzy matching) | Levenshtein distance on normalized company+title. URL normalization for exact matches. |
| **Search Platforms** | Multi-platform | LinkedIn (primary), Indeed, Glassdoor, ZipRecruiter, Korn Ferry, Heidrick & Struggles |
| **Application Processing** | Sequential (one at a time) | Systematic and automated, but not parallel. Reduces complexity and error surface. |

---

## Open Questions (Round 3)

| Question | Options | Impact |
|----------|---------|--------|
| **Chrome profile for Playwright** | Separate profile vs Wolf's existing | Separate avoids interference but needs re-login to sites |
| **Gmail OAuth setup** | Has Google Cloud project? | One-time setup (~15 min) needed if not |
| **Anthropic API key** | Has key vs route through Max plan | API key needed for direct Claude API calls |
| **Resume file path** | Exact path on Mac | Needed for auto-copy configuration |
| **Secondary display** | Available for Playwright browser? | Determines if automation takes over main screen |

---

## Technology Stack (Complete)

### Existing (Phase 1-6)
- **Runtime:** Node.js
- **Server:** Express.js
- **Database:** SQLite (better-sqlite3)
- **Dashboard:** Single-file HTML/CSS/JS
- **MCP:** Custom JSON-RPC over stdio

### New (Phase 7+)
- **Browser Automation:** Playwright
- **WebSocket:** ws
- **Scheduling:** node-cron
- **Job Queue:** better-queue
- **Fuzzy Search:** Fuse.js
- **Process Manager:** pm2
- **AI API:** @anthropic-ai/sdk
- **Gmail:** googleapis (Google APIs Node.js client)
- **Chrome Extension:** Manifest V3

### Dependencies (package.json additions)
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

---

## Architecture Principles

1. **Human-in-the-loop at critical points** — Job approval and final submit only
2. **Full automation everywhere else** — Scoring, folder creation, cover letter, form filling
3. **One application at a time** — Sequential processing, no parallel submissions
4. **Archive everything** — JSON files by date, all data in SQLite, never delete
5. **Graceful degradation** — Challenges tab for when automation can't proceed
6. **Manual takeover/handback** — Wolf can intervene at any point and return control
7. **Deduplication first** — Never apply to the same job twice, across all platforms
8. **Blinking means action** — Single clear indicator when human attention needed
