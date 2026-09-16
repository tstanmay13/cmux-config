#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0

check_link() {
  local target_path="$1"
  local expected_path="$2"

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$expected_path" ]; then
    echo "OK $target_path"
  else
    echo "FAIL $target_path is not linked to $expected_path"
    failed=1
  fi
}

check_link "$HOME/.config/cmux/cmux.json" "$repo_dir/cmux/cmux.json"
check_link "$HOME/.config/ghostty/config" "$repo_dir/ghostty/config"

if bash -n "$repo_dir/scripts/new-worktree-workspace.sh"; then
  echo "OK worktree workspace helper syntax"
else
  echo "FAIL worktree workspace helper syntax"
  failed=1
fi

if command -v cmux >/dev/null 2>&1; then
  cmux config doctor
else
  echo "FAIL cmux is not installed"
  failed=1
fi

if command -v codex >/dev/null 2>&1; then
  if [ -f "$HOME/.codex/hooks.json" ] && grep -q 'cmux-codex-hook' "$HOME/.codex/hooks.json"; then
    echo "OK Codex cmux hooks"
  else
    echo "FAIL Codex cmux hooks are missing; run: cmux hooks codex install --yes"
    failed=1
  fi
fi

exit "$failed"
