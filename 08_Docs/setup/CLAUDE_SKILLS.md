# Claude Skills Installation Guide

53 skills from [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) — CEO advisor, CTO advisor, architect, DevOps, SecOps, PM, marketing, product, finance, and more.

## Quick Install (Any Machine)

**Prerequisites:** git installed

### Option 1: Run the script (from inside this repo)

```bash
cd /path/to/Archive-35
./06_Automation/scripts/install-claude-skills.sh
```

This installs skills for both Claude Code CLI (`~/.claude/skills/`) and Coworker (`.claude/skills/`) in one go.

Use `--cli-only` to skip the Coworker install:
```bash
./06_Automation/scripts/install-claude-skills.sh --cli-only
```

### Option 2: Manual install

```bash
git clone --depth 1 https://github.com/alirezarezvani/claude-skills.git /tmp/claude-skills

cp -r /tmp/claude-skills/marketing-skill ~/.claude/skills/
cp -r /tmp/claude-skills/engineering-team ~/.claude/skills/
cp -r /tmp/claude-skills/product-team ~/.claude/skills/
cp -r /tmp/claude-skills/c-level-advisor ~/.claude/skills/
cp -r /tmp/claude-skills/project-management ~/.claude/skills/
cp -r /tmp/claude-skills/ra-qm-team ~/.claude/skills/
cp -r /tmp/claude-skills/business-growth ~/.claude/skills/
cp -r /tmp/claude-skills/finance ~/.claude/skills/

rm -rf /tmp/claude-skills
```

## What Gets Installed

| Folder | Skills | Examples |
|--------|--------|---------|
| `c-level-advisor` | 2 | CEO advisor, CTO advisor |
| `engineering-team` | 18 | Architect, DevOps, SecOps, AWS, ML |
| `project-management` | 6 | Scrum master, PM, Jira, Confluence |
| `product-team` | 5 | Strategist, PM toolkit, agile PO, UX |
| `marketing-skill` | 6 | Content creator, social media |
| `ra-qm-team` | 12 | Compliance, QA |
| `business-growth` | 3 | Revenue ops, sales engineer, customer success |
| `finance` | 1 | Financial analyst |

## Per-Machine Setup

Skills are local to each machine. Run the script or manual steps on each Mac/computer where you use Claude Code.

## Coworker (GitHub)

Skills committed to the repo's `.claude/skills/` directory are automatically available to Coworker sessions.

The install script handles this when run from inside a repo. To do it manually:

```bash
cd /path/to/Archive-35
git clone --depth 1 https://github.com/alirezarezvani/claude-skills.git /tmp/claude-skills

cp -r /tmp/claude-skills/marketing-skill .claude/skills/
cp -r /tmp/claude-skills/engineering-team .claude/skills/
cp -r /tmp/claude-skills/product-team .claude/skills/
cp -r /tmp/claude-skills/c-level-advisor .claude/skills/
cp -r /tmp/claude-skills/project-management .claude/skills/
cp -r /tmp/claude-skills/ra-qm-team .claude/skills/
cp -r /tmp/claude-skills/business-growth .claude/skills/
cp -r /tmp/claude-skills/finance .claude/skills/

rm -rf /tmp/claude-skills

git add .claude/skills/
git commit -m "Add Claude skills for Coworker"
git push
```

## Updating Skills

Re-run the install script or manual steps. The `cp -r` overwrites existing folders with the latest versions.

## Uninstall

```bash
rm -rf ~/.claude/skills/{marketing-skill,engineering-team,product-team,c-level-advisor,project-management,ra-qm-team,business-growth,finance}

rm -rf .claude/skills/{marketing-skill,engineering-team,product-team,c-level-advisor,project-management,ra-qm-team,business-growth,finance}
```

## Limitations

- **Claude.ai (browser):** Does not support file-based skills. Use Projects with custom instructions instead.
- **Claude mobile app:** Same as browser — no file-based skill support.
- **Each machine needs its own install** — skills don't sync between computers.
