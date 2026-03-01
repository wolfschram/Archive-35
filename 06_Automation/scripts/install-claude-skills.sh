#!/bin/bash
# ============================================================================
# Install Claude Skills (alirezarezvani/claude-skills)
# 53 skills for Claude Code CLI + project-level for Coworker
#
# Usage:
#   chmod +x install-claude-skills.sh
#   ./install-claude-skills.sh              # Install CLI + Coworker (if in a repo)
#   ./install-claude-skills.sh --cli-only   # Install CLI only
#
# Prerequisites: git
# Source: https://github.com/alirezarezvani/claude-skills
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/alirezarezvani/claude-skills.git"
TMP_DIR="/tmp/claude-skills-$$"
SKILLS_DIR="$HOME/.claude/skills"
CLI_ONLY=false

# Skill category folders (contain 53 individual skills total)
SKILL_FOLDERS=(
    "marketing-skill"       # 6 skills
    "engineering-team"      # 18 skills
    "product-team"          # 5 skills
    "c-level-advisor"       # 2 skills
    "project-management"    # 6 skills
    "ra-qm-team"           # 12 skills
    "business-growth"       # 3 skills
    "finance"              # 1 skill
)

# Parse args
for arg in "$@"; do
    case $arg in
        --cli-only) CLI_ONLY=true ;;
    esac
done

echo ""
echo "========================================="
echo "  Claude Skills Installer (53 skills)"
echo "========================================="
echo ""

# --- Prerequisite checks ---
if ! command -v git &> /dev/null; then
    echo -e "${RED}ERROR: git not found.${NC}"
    exit 1
fi

# --- Step 1: Clone the repo ---
echo -e "${GREEN}[1/4] Cloning alirezarezvani/claude-skills...${NC}"
git clone --depth 1 "$REPO_URL" "$TMP_DIR" 2>&1 | tail -1
echo ""

# --- Step 2: Install for Claude Code CLI (user-level) ---
echo -e "${GREEN}[2/4] Installing skills for Claude Code CLI...${NC}"
echo "      Target: $SKILLS_DIR/"
mkdir -p "$SKILLS_DIR"

for folder in "${SKILL_FOLDERS[@]}"; do
    if [ -d "$TMP_DIR/$folder" ]; then
        cp -r "$TMP_DIR/$folder" "$SKILLS_DIR/"
        echo "      + $folder"
    else
        echo -e "      ${YELLOW}! $folder not found in repo (skipped)${NC}"
    fi
done

CLI_COUNT=$(ls "$SKILLS_DIR" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "      Installed ${CLI_COUNT} skill folders to $SKILLS_DIR/"

# --- Step 3: Install for Coworker (project-level) ---
PROJECT_COUNT=0
REPO_ROOT=""

if [ "$CLI_ONLY" = false ]; then
    echo ""
    echo -e "${GREEN}[3/4] Installing skills for Coworker (project-level)...${NC}"

    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    if [ -n "$REPO_ROOT" ]; then
        PROJECT_SKILLS="$REPO_ROOT/.claude/skills"
        echo "      Target: $PROJECT_SKILLS/"
        mkdir -p "$PROJECT_SKILLS"

        for folder in "${SKILL_FOLDERS[@]}"; do
            if [ -d "$TMP_DIR/$folder" ]; then
                cp -r "$TMP_DIR/$folder" "$PROJECT_SKILLS/"
                echo "      + $folder"
            else
                echo -e "      ${YELLOW}! $folder not found in repo (skipped)${NC}"
            fi
        done

        PROJECT_COUNT=$(ls "$PROJECT_SKILLS" 2>/dev/null | wc -l | tr -d ' ')
        echo ""
        echo "      Installed ${PROJECT_COUNT} skill folders to $PROJECT_SKILLS/"
        echo ""
        echo -e "${YELLOW}      Remember to commit and push for Coworker:${NC}"
        echo "      cd $REPO_ROOT"
        echo "      git add .claude/skills/"
        echo "      git commit -m \"Add Claude skills for Coworker\""
        echo "      git push"
    else
        echo -e "${YELLOW}      Not inside a git repo. Skipping Coworker install.${NC}"
        echo "      To install for Coworker, cd into your repo and re-run this script."
    fi
else
    echo ""
    echo -e "${YELLOW}[3/4] Skipping Coworker install (--cli-only)${NC}"
fi

# --- Step 4: Clean up ---
echo ""
echo -e "${GREEN}[4/4] Cleaning up...${NC}"
rm -rf "$TMP_DIR"
echo "      Removed $TMP_DIR"

# --- Summary ---
echo ""
echo "========================================="
echo "  Installation Complete"
echo "========================================="
echo ""
echo "  CLI skills:     $SKILLS_DIR/ ($CLI_COUNT folders)"
if [ -n "$REPO_ROOT" ] && [ "$CLI_ONLY" = false ]; then
    echo "  Coworker skills: $REPO_ROOT/.claude/skills/ ($PROJECT_COUNT folders)"
fi
echo ""
echo "  Verify:   ls $SKILLS_DIR/"
echo "  Update:   Re-run this script"
echo "  Remove:   rm -rf $SKILLS_DIR/{$(IFS=,; echo "${SKILL_FOLDERS[*]}")}"
echo ""
echo -e "${GREEN}Done!${NC} Restart Claude Code to pick up the new skills."
