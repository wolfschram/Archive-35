#!/bin/bash
# ============================================================================
# Install Claude Skills (alirezarezvani/claude-skills)
# All 53 skills for Claude Code CLI + project-level for Coworker
#
# Usage:
#   chmod +x install-claude-skills.sh
#   ./install-claude-skills.sh
#
# Prerequisites: Node.js (for npx), Claude Code CLI installed
# Source: https://github.com/alirezarezvani/claude-skills
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "========================================="
echo "  Claude Skills Installer (53 skills)"
echo "========================================="
echo ""

# --- Prerequisite checks ---
if ! command -v npx &> /dev/null; then
    echo -e "${RED}ERROR: npx not found.${NC}"
    echo "Install Node.js first: brew install node"
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}WARNING: Claude Code CLI not detected in PATH.${NC}"
    echo "Skills will still install to ~/.claude/skills/ but verify Claude Code is set up."
    echo ""
fi

# --- Step 1: Install for Claude Code CLI (user-level) ---
echo -e "${GREEN}[1/3] Installing all 53 skills for Claude Code CLI...${NC}"
echo "      Target: ~/.claude/skills/"
echo ""
npx agent-skills-cli add alirezarezvani/claude-skills --agent claude

echo ""
echo -e "${GREEN}[2/3] Verifying CLI installation...${NC}"
SKILL_COUNT=$(ls ~/.claude/skills/ 2>/dev/null | wc -l | tr -d ' ')
echo "      Found ${SKILL_COUNT} skill folders in ~/.claude/skills/"

if [ "$SKILL_COUNT" -lt 50 ]; then
    echo -e "${YELLOW}WARNING: Expected 53+ skills, got ${SKILL_COUNT}.${NC}"
    echo "Some skills may not have installed correctly."
else
    echo -e "${GREEN}      All skills installed successfully.${NC}"
fi

# --- Step 2: Install for Coworker (project-level) ---
echo ""
echo -e "${GREEN}[3/3] Installing skills at project level for Coworker...${NC}"

# Find the repo root (look for .git directory)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

if [ -n "$REPO_ROOT" ]; then
    echo "      Target: ${REPO_ROOT}/.claude/skills/"
    cd "$REPO_ROOT"
    npx agent-skills-cli add alirezarezvani/claude-skills --agent project
    PROJECT_COUNT=$(ls .claude/skills/ 2>/dev/null | wc -l | tr -d ' ')
    echo "      Found ${PROJECT_COUNT} skill folders in repo .claude/skills/"
else
    echo -e "${YELLOW}      Not inside a git repo. Skipping project-level install.${NC}"
    echo "      To install for Coworker, cd into your repo and run:"
    echo "      npx agent-skills-cli add alirezarezvani/claude-skills --agent project"
fi

# --- Summary ---
echo ""
echo "========================================="
echo "  Installation Complete"
echo "========================================="
echo ""
echo "  CLI skills:     ~/.claude/skills/ (${SKILL_COUNT} folders)"
if [ -n "$REPO_ROOT" ]; then
    echo "  Coworker skills: ${REPO_ROOT}/.claude/skills/ (${PROJECT_COUNT:-0} folders)"
fi
echo ""
echo "  Verify:  ls ~/.claude/skills/"
echo "  Update:  npx agent-skills-cli add alirezarezvani/claude-skills --agent claude"
echo "  Remove:  rm -rf ~/.claude/skills/alirezarezvani/"
echo ""
echo -e "${GREEN}Done!${NC} Restart Claude Code to pick up the new skills."
