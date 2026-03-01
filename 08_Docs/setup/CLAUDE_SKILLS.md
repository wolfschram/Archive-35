# Claude Skills Installation Guide

53 skills from [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) — CEO advisor, CTO advisor, architect, DevOps, SecOps, PM, marketing, product, finance, and more.

## Quick Install (Any Machine)

**Prerequisites:** Node.js installed (`brew install node` on macOS)

### Option 1: Run the script (from this repo)

```bash
cd /path/to/Archive-35
./06_Automation/scripts/install-claude-skills.sh
```

This installs skills for both Claude Code CLI and Coworker in one go.

### Option 2: One-liner

```bash
npx agent-skills-cli add alirezarezvani/claude-skills --agent claude
```

## What Gets Installed

| Category | Skills | Examples |
|----------|--------|---------|
| C-Level Advisory | 2 | CEO advisor, CTO advisor |
| Engineering | 18 | Architect, DevOps, SecOps, AWS, ML |
| Project Management | 6 | Scrum master, PM, Jira, Confluence |
| Product | 5 | Strategist, PM toolkit, agile PO, UX |
| Marketing | 6 | Content creator, social media |
| Regulatory/Quality | 12 | Compliance, QA |
| Business Growth | 3 | Revenue ops, sales engineer, customer success |
| Finance | 1 | Financial analyst |

## Per-Machine Setup

Skills are local to each machine. Run on each Mac/computer where you use Claude Code:

```bash
# Install for Claude Code CLI
npx agent-skills-cli add alirezarezvani/claude-skills --agent claude

# Verify
ls ~/.claude/skills/ | wc -l
# Should show 53+
```

## Coworker (GitHub)

Skills committed to the repo's `.claude/skills/` directory are automatically available to Coworker sessions:

```bash
cd /path/to/Archive-35
npx agent-skills-cli add alirezarezvani/claude-skills --agent project
git add .claude/skills/
git commit -m "Add 53 Claude skills for Coworker"
git push
```

## Updating Skills

```bash
npx agent-skills-cli add alirezarezvani/claude-skills --agent claude
```

Re-running the install command pulls the latest versions.

## Uninstall

```bash
# Remove all skills
rm -rf ~/.claude/skills/alirezarezvani/

# Remove project-level skills
rm -rf .claude/skills/alirezarezvani/
```

## Limitations

- **Claude.ai (browser):** Does not support file-based skills. Use Projects with custom instructions instead.
- **Claude mobile app:** Same as browser — no file-based skill support.
- **Each machine needs its own install** — skills don't sync between computers.
