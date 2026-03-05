# Job Pipeline v2 — Planning Decisions Log

> Complete record of all decisions made during the planning sessions (March 2026)

---

## Round 1: Initial Architecture Questions

### Q1: Where should scraped job data land?
**Decision:** JSON files dropped into `Job-Pipeline/scraped/{YYYY-MM-DD}/` organized by date. Chrome extension sends data to Express API, server writes the files. All data also stored in SQLite.

### Q2: What does "Copy Prompt into Coworker" actually mean?
**Decision:** NOT clipboard copy. When engaging Claude Coworker, the full job context should be immediately available — cover letter preparation, understanding the application workflow, researching the company's process. This means the command center needs to prepare a complete context package.

### Q3: Architecture complexity — webhook vs persistent?
**Decision:** Full persistent architecture needed. Simple webhooks won't work given the complexity of multi-step application workflows, account creation, email verification loops, and human-in-the-loop patterns.

### Q4: Volume — how many jobs per session?
**Decision:** 5-10 quality matches per search session. Search prompt must be sophisticated with guardrails and guidelines. After completing a search, system waits 3 hours before next search to avoid rate limiting and manage workflow.

### Q5: Resume/cover letter upload approach?
**Decision:** If the Cafe upload pattern works easily, use it. If it causes problems, don't spend hours fixing it. Instead, create a "Challenges" tab with manual intervention capability. Wolf can take over manually and hand back to automation.

### Q6: Form filling automation level?
**Decision:** Option C — Full automation. Claude fills out everything possible using data from the Personal Info tab. Only pauses for final human approval before submitting. Blinking notification button when action needed.

### Q7: Cover letter output location?
**Decision:** Auto-created folder: `Job-Pipeline/applied/{company-title}/` containing resume, cover letter, job posting link, job details. Folder structure created automatically when job is approved for application.

### Q8: Parallel Claude sessions?
**Decision:** Wolf frequently runs Claude Coworker, Claude browser extension, and Claude plugin simultaneously, sometimes in multiple tabs. System must handle concurrent access. Applications processed one at a time but systematically. 3-hour window between searches where system processes applications.

### Q9: LinkedIn integration?
**Decision:** Already proven that Claude Chrome plugin works well with LinkedIn. Want both: automated search via extension AND manual job addition via URL paste in command center.

### Q10: Automation approach?
**Decision:** Full automation from day one. No semi-manual MVP. Conductor orchestrates everything.

---

## Round 2: Technical Architecture Questions

### Q1: Server always running?
**Decision:** Yes, acceptable. Express server runs at localhost:3000 whenever job searching is active.

### Q2: Extension scope — LinkedIn only or multi-platform?
**Decision:** Multi-platform. LinkedIn, Indeed, Glassdoor, executive recruiters (Korn Ferry, Heidrick & Struggles). Platforms with backend APIs should use those; others use Claude browser extension for visual browsing.

### Q3: Claude extension vs custom Chrome extension?
**Decision:** BOTH.
- **Claude browser extension** (official, already installed) handles all web interaction — reading pages, searching, filling forms
- **Custom Chrome Bridge extension** (to be built) handles ONLY file drop-off bridge and prompt loading — things the Claude extension cannot do

### Q4: "Start Search" button — how it triggers extension?
**Decision:** Option C preferred — button sets flag in DB, extension polls for it and auto-activates. But additional question raised: how does the extension auto-load the prompt with the latest exclusion list? This needs the Chrome Bridge to fetch the prompt from the API and make it available.

### Q5: Anti-detection / LinkedIn restrictions?
**Decision:** No restrictions encountered during manual testing. Continue with current approach, monitor for issues.

### Q6: Full automation — Claude extension vs Puppeteer/Playwright?
**Decision:** Playwright for the mechanical browser automation (form filling, file uploads, navigation). Claude browser extension for the intelligent parts (reading job descriptions, making decisions). Human-in-the-loop for CAPTCHAs via red tally light.

### Q7: Personal Info form — how detailed?
**Decision:** Comprehensive. Research the top 20 job platforms and compile all common form fields. Wolf will fill out the complete form once, system uses it for all applications.

### Q8: Account creation — security?
**Decision:** Plaintext password storage. Same email and password for all job sites. No encryption complexity needed — Wolf's assessment is that job search credentials are not sensitive.

### Q9: Verification code flow?
**Decision:** Wait-and-retry approach. Gmail MCP server checks inbox, extracts code/link, feeds back to browser automation. System waits up to 5 minutes, retrying. Does not flag as Challenge unless timeout exceeded.

### Q10: Where does the Conductor live?
**Decision:** Separate Node.js process (conductor.js). NOT Claude Desktop/Coworker. Fully automated, independent process managed by pm2.

### Q11: Job approval workflow?
**Decision:** Command Center dashboard. Wolf opens scored job, reviews it, clicks "Approve" button. This triggers the ENTIRE downstream workflow: folder creation → cover letter generation → application start.

### Q12: Blinking notification — how?
**Decision:** All three methods:
- WebSocket for instant dashboard updates
- Browser Notification API for OS-level alerts
- Centralized "Action Needed" tab listing all pending items with direct links

### Q13: 3-hour window — purpose?
**Decision:** Primarily for LinkedIn rate-limit protection. During downtime, conductor processes pending applications and analyzes feedback. System is NOT idle — it shifts from search mode to application mode.

### Q14: Resume — single or tailored?
**Decision:** Single master resume for all applications. Tailoring happens in the cover letter only. One PDF stored at `Job-Pipeline/resume/wolf-resume-master.pdf`.

### Q15: Date-organized JSON files?
**Decision:** Yes, `scraped/{YYYY-MM-DD}/{company-title}.json`. JSONs always stay as archive AND get absorbed into SQLite. Never delete — prevents duplicate applications.

### Q16: Gmail MCP scope?
**Decision:** Read verification emails + monitor recruiter responses. NEVER send emails. Personal Gmail account, not a dedicated job-search account. Filter only job-related emails.

### Q17: Concurrent access conflict prevention?
**Decision:** SQLite with WAL mode is sufficient for the volume (5-10 jobs per session). Conductor manages write coordination. Deduplication prevents multiple Claude instances from adding the same job twice.

### Q18: Daily workflow?
**Decision:** Job search runs alongside other work (photography, Lighthaus). Conductor should indicate when coworker is needed for pipeline work — "red light" if Wolf is using coworker for other tasks and pipeline needs it.

### Q19: Build order?
**Decision:** Wolf defers to Claude's judgment on sequencing. The goal is a full-blown functioning system at the end. No preference on which component comes first.

### Q20: Minimum viable conductor?
**Decision:** NO MVP. Full automation from day one. Form filling, account creation, email verification — everything must be included. Clear layered architecture but no shortcuts in scope.

---

## Quick-Answer Round (Final Technical Decisions)

### Resume file format?
**Decision:** PDF file on Wolf's Mac. Path to be provided. System copies it into each `applied/{job}/` folder.

### Target machine?
**Decision:** Wolf's main Mac (daily driver). Playwright opens visible browser on the same display.

### Cover letter generation method?
**Decision:** Claude API direct call from conductor using Anthropic SDK. Automated, no human involvement. Hallucination filter runs after generation.

### Job queue technology?
**Decision:** `better-queue` with SQLite backend. No Redis dependency. Single-user local system doesn't need Bull/BullMQ complexity.

---

## Remaining Open Questions (Round 3)

1. **Chrome profile** — Separate profile for Playwright or use Wolf's existing one?
2. **Gmail OAuth** — Google Cloud project + OAuth setup needed?
3. **Anthropic API key** — Does Wolf have one, or route through Max plan?
4. **Resume exact path** — File location on Mac
5. **Secondary display** — Available for Playwright browser, or shares main screen?
