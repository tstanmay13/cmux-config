#!/usr/bin/env bash

# This file is sourced by a new cmux workspace so its final `cd` changes the
# interactive shell's directory. Keep all variables local to avoid polluting it.
_cmux_new_worktree_main() {
  local repo_root remote_url task_name slug branch worktree_root worktree_path

  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'Not inside a Git repository; leaving this as a normal workspace.\n'
    return 0
  }

  remote_url="$(git -C "$repo_root" remote get-url origin 2>/dev/null)" || {
    printf 'This repository has no origin remote; leaving this as a normal workspace.\n'
    return 0
  }

  case "$remote_url" in
    *Standard-Template-Labs/repo|*Standard-Template-Labs/repo.git) ;;
    *)
      printf 'This automatic worktree flow is configured only for Standard-Template-Labs/repo.\n'
      printf 'Leaving this as a normal workspace in %s.\n' "$repo_root"
      return 0
      ;;
  esac

  if [ -n "${CMUX_WORKTREE_TASK:-}" ]; then
    task_name="$CMUX_WORKTREE_TASK"
  else
    printf 'Task name (for example, ticket-search-timeout): '
    IFS= read -r task_name
  fi

  slug="$(printf '%s' "$task_name" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-64)"

  if [ -z "$slug" ]; then
    printf 'No usable task name was provided; no worktree was created.\n'
    return 1
  fi

  branch="tanmaysingh/$slug"
  worktree_root="$HOME/Documents/stlabs/worktrees"
  worktree_path="$worktree_root/$slug"

  if ! git check-ref-format --branch "$branch" >/dev/null 2>&1; then
    printf 'The resolved branch name is not valid: %s\n' "$branch"
    return 1
  fi

  if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
    printf 'Branch already exists: %s\n' "$branch"
    printf 'No worktree was created.\n'
    return 1
  fi

  if [ -e "$worktree_path" ]; then
    printf 'Path already exists: %s\n' "$worktree_path"
    printf 'No worktree was created.\n'
    return 1
  fi

  printf '\nTask:     %s\n' "$task_name"
  printf 'Branch:   %s\n' "$branch"
  printf 'Base:     origin/main\n'
  printf 'Worktree: %s\n\n' "$worktree_path"

  if [ "${CMUX_WORKTREE_DRY_RUN:-0}" = "1" ]; then
    printf 'Dry run: no worktree was created.\n'
    return 0
  fi

  mkdir -p "$worktree_root" || return 1

  printf 'Refreshing origin/main...\n'
  git -C "$repo_root" fetch origin main || {
    printf 'Could not refresh origin/main; no worktree was created.\n'
    return 1
  }

  git -C "$repo_root" worktree add -b "$branch" "$worktree_path" origin/main || return 1
  cd "$worktree_path" || return 1

  if command -v cmux >/dev/null 2>&1 && [ -n "${CMUX_WORKSPACE_ID:-}" ]; then
    cmux rename-workspace --workspace "$CMUX_WORKSPACE_ID" "$slug" >/dev/null 2>&1 || true
  fi

  printf '\nReady in %s\n' "$worktree_path"
  printf 'Worktrees are never deleted automatically.\n'
}

_cmux_new_worktree_main
_cmux_new_worktree_status=$?
unset -f _cmux_new_worktree_main

# Return from a sourced script without turning a non-zero return into `exit`.
case "${ZSH_EVAL_CONTEXT:-}" in
  *:file)
    case "$_cmux_new_worktree_status" in
      0) unset _cmux_new_worktree_status; return 0 ;;
      *) unset _cmux_new_worktree_status; return 1 ;;
    esac
    ;;
esac

if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "$0" ]; then
  case "$_cmux_new_worktree_status" in
    0) unset _cmux_new_worktree_status; return 0 ;;
    *) unset _cmux_new_worktree_status; return 1 ;;
  esac
fi

exit "$_cmux_new_worktree_status"
