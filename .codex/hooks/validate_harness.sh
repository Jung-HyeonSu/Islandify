#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

required_files="
$repo_root/AGENTS.md
$repo_root/.agents/skills/islandify-ios/SKILL.md
$repo_root/.codex/config.toml
$repo_root/.codex/hooks.json
$repo_root/.codex/hooks/verify_goal.sh
$repo_root/.codex/agents/ios-architect.toml
$repo_root/.codex/agents/ios-implementer.toml
$repo_root/.codex/agents/live-activity-reviewer.toml
$repo_root/.codex/rules/default.rules
$repo_root/.codex/ticket/001-harness-and-timer.md
$repo_root/.codex/ticket/002-islandify-v1-goal.md
"

for file in $required_files; do
  if [ ! -f "$file" ]; then
    printf 'Missing required harness file: %s\n' "$file" >&2
    exit 1
  fi
done

printf 'Islandify harness: OK\n'
