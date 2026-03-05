# Job Pipeline v2 — Requirements

> All requirements captured from planning sessions, organized by workstream

---

## Workstream A: Chrome Extension (Search Engine)

| # | Requirement | Source | Status |
|---|------------|--------|--------|
| A1 | Research Chrome extension architecture from scratch (Manifest V3) | Q1 R1 | Planned |
| A2 | Build extension that bridges Claude browser ext ↔ local Express API | Q3 R2 | Planned |
| A3 | Load sophisticated search prompt into extension from Command Center | Q4 R2 | Planned |
| A4 | Extension drops JSON files into `Job-Pipeline/scraped/{date}/` | Q1 R1 | Planned |
| A5 | "Start Search" button on Command Center triggers search flow | Q4 R2 | Planned |
| A6 | 3-hour cooldown between search sessions (auto-scheduling) | Q4 R1 | Planned |
| A7 | Extension works with LinkedIn authentication (proven manually) | Q9 R1 | Validated |
| A8 | Search prompt includes exclusion list of already-pipelined jobs | Q2 R2 | Planned |
| A9 | 5-10 quality matches per session with guardrails | Q4 R1 | Planned |
| A10 | Multi-platform: LinkedIn, Indeed, Glassdoor, executive recruiters | Q2 R2 | Planned |
| A11 | Submit results per-platform before moving to next (not all at once) | Q2 R2 | Planned |
| A12 | Detect and prevent re-surfacing of known jobs | Q2 R2 | Planned |

---

## Workstream B: Command Center — New Tabs

| # | Requirement | Source | Status |
|---|------------|--------|--------|
| B1 | **Personal Info tab** — form for email, password, veteran status, disability, race/ethnicity, all common application questions | Q2 R1, Q7 R2 | Planned |
| B2 | **Challenges tab** — manual intervention tracking, blockers, holding patterns, links to relevant pages | Q5 R1 | Planned |
| B3 | **Research Prompt tab** — categories, importance grades, do's/don'ts, exclusion list, prompt preview | R2 additions | Planned |
| B4 | **Applied Folders tab** — file browser for `applied/{company}/` with file inventory | Q7 R1 | Planned |
| B5 | **Feedback tab** — Wolf's workflow observations, categorized (bug, improvement, question) | Q13 R2 | Planned |
| B6 | **Add Job URL input** — paste URL to manually add jobs from personal browsing | Q9 R1 | Planned |
| B7 | **Start Search button** — triggers Chrome → LinkedIn login → plugin activation | Q4 R2 | Planned |
| B8 | **ACTION NEEDED blinking indicator** — red tally light for all pending human actions | Q6 R1, Q12 R2 | Planned |
| B9 | **Coworker status** — FREE/BUSY indicator, alert when pipeline needs coworker | Q18 R2 | Planned |
| B10 | **Next Search Timer** — countdown to next scheduled search cycle | Q13 R2 | Planned |

---

## Workstream C: Automated Application Flow

| # | Requirement | Source | Status |
|---|------------|--------|--------|
| C1 | Auto-create folder on approval: `applied/{company-title}/` with resume, cover letter, job link | Q7 R1 | Planned |
| C2 | Claude fills out application forms completely (full automation, human approval at final submit) | Q6 R1, Q6 R2 | Planned |
| C3 | Handle account creation on job sites (same email/password for all) | Q2 R1 | Planned |
| C4 | Handle login workflows and email verification codes | Q2 R1, Q9 R2 | Planned |
| C5 | Blinking notification when human action required | Q6 R1 | Planned |
| C6 | Detect CAPTCHAs and alert human for intervention | Q6 R2 | Planned |
| C7 | Manual takeover capability (Wolf takes control → hands back) | Q5 R1, B2 | Planned |
| C8 | One application at a time, sequential processing | Q8 R1 | Planned |
| C9 | Cover letter generated via Claude API with hallucination filter | Q7 R1, Quick Answers | Planned |
| C10 | Application log written to `applied/{company}/application-log.md` | Architecture | Planned |
| C11 | Screenshot on error saved to Challenges tab | Architecture | Planned |

---

## Workstream D: Infrastructure

| # | Requirement | Source | Status |
|---|------------|--------|--------|
| D1 | Gmail MCP server for verification emails and recruiter response monitoring | Q2 R1 | Planned |
| D2 | Gmail: read-only, NEVER send emails | Q16 R2 | Confirmed |
| D3 | Resume storage at `Job-Pipeline/resume/wolf-resume-master.pdf` | Q14 R2, Quick Answers | Planned |
| D4 | Conductor (separate Node.js process) orchestrating all agents | Q10 R2 | Planned |
| D5 | Auto-start all services on computer reboot (pm2 + launchd) | R2 additions | Planned |
| D6 | Deduplication across platforms (same job on LinkedIn + Indeed = one entry) | Q17 R2 | Planned |
| D7 | Exclusion list auto-maintained in search prompt | Q2 R2, A8 | Planned |
| D8 | SQLite with WAL mode sufficient for concurrent access | Q17 R2 | Confirmed |
| D9 | better-queue with SQLite backend (no Redis) | Quick Answers | Confirmed |
| D10 | Claude API direct call for cover letter generation (Anthropic SDK) | Quick Answers | Confirmed |
| D11 | Playwright in headed mode on main Mac display | Quick Answers | Confirmed |
| D12 | Plaintext password storage (Wolf's preference) | Q8 R2 | Confirmed |

---

## Workstream E: Quality & Safety

| # | Requirement | Source | Status |
|---|------------|--------|--------|
| E1 | Hallucination filter for cover letters (verify claims against context files) | Q14 R2 | Planned |
| E2 | Never apply to same job twice (deduplication + exclusion list) | Q15 R2 | Planned |
| E3 | Archive all search results as JSON files (never delete) | Q15 R2 | Confirmed |
| E4 | Track rejection reasons for excluded jobs (prompt learning) | Q15 R2 | Planned |
| E5 | Salary strategy: always just under max posted range | Q7 R2 | Confirmed |
| E6 | Feedback loop: template version A/B testing for cover letters (exists) | Phase 6 | Complete |

---

## Legend

- **Q{n} R{n}** — Question number, Round number from planning sessions
- **Status values:** Complete, Confirmed (decision made), Planned (to be built), Validated (tested manually)
