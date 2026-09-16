#!/usr/bin/env bash

# This file is sourced by a new cmux workspace so its final `cd` changes the
# interactive shell's directory. Keep all variables local to avoid polluting it.
_cmux_new_worktree_main() {
  local repo_root common_dir_raw common_dir canonical_root repo_name
  local branch_prefix task_name slug branch configured_root worktree_root worktree_path
  local remote base_ref base_remote base_branch configured_base

  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'Not inside a Git repository; leaving this as a normal workspace.\n'
    return 0
  }

  common_dir_raw="$(git -C "$repo_root" rev-parse --git-common-dir)" || return 1
  case "$common_dir_raw" in
    /*) common_dir="$common_dir_raw" ;;
    *) common_dir="$(cd "$repo_root/$common_dir_raw" 2>/dev/null && pwd -P)" || return 1 ;;
  esac

  if [ "$(git -C "$repo_root" rev-parse --is-bare-repository 2>/dev/null)" = "true" ]; then
    canonical_root="$common_dir"
  else
    canonical_root="${common_dir%/.git}"
  fi
  repo_name="$(basename "$canonical_root" .git)"

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

  if git -C "$repo_root" config --get cmux.branchPrefix >/dev/null 2>&1; then
    branch_prefix="$(git -C "$repo_root" config --get cmux.branchPrefix)"
  else
    branch_prefix="tanmaysingh"
  fi
  branch_prefix="${branch_prefix%/}"
  if [ -n "$branch_prefix" ]; then
    branch="$branch_prefix/$slug"
  else
    branch="$slug"
  fi

  configured_root="$(git -C "$repo_root" config --get cmux.worktreeRoot 2>/dev/null || true)"
  if [ -n "$configured_root" ]; then
    case "$configured_root" in
      "~/"*) worktree_root="$HOME/${configured_root#\~/}" ;;
      /*) worktree_root="$configured_root" ;;
      *) worktree_root="$canonical_root/$configured_root" ;;
    esac
  else
    worktree_root="$(dirname "$canonical_root")/${repo_name}-worktrees"
  fi
  worktree_path="$worktree_root/$slug"

  configured_base="$(git -C "$repo_root" config --get cmux.worktreeBase 2>/dev/null || true)"
  if [ -n "$configured_base" ]; then
    base_ref="$configured_base"
  else
    if git -C "$repo_root" remote get-url origin >/dev/null 2>&1; then
      remote="origin"
    else
      remote="$(git -C "$repo_root" remote | sed -n '1p')"
    fi

    if [ -n "$remote" ]; then
      base_ref="$(git -C "$repo_root" symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null || true)"
      if [ -z "$base_ref" ] && git -C "$repo_root" show-ref --verify --quiet "refs/remotes/$remote/main"; then
        base_ref="$remote/main"
      fi
      if [ -z "$base_ref" ] && git -C "$repo_root" show-ref --verify --quiet "refs/remotes/$remote/master"; then
        base_ref="$remote/master"
      fi
      if [ -z "$base_ref" ]; then
        base_branch="$(git -C "$repo_root" ls-remote --symref "$remote" HEAD 2>/dev/null \
          | awk '$1 == "ref:" { sub("refs/heads/", "", $2); print $2; exit }')"
        if [ -n "$base_branch" ]; then
          base_ref="$remote/$base_branch"
        fi
      fi
    fi
    base_ref="${base_ref:-HEAD}"
  fi

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
  printf 'Repository: %s\n' "$canonical_root"
  printf 'Branch:   %s\n' "$branch"
  printf 'Base:     %s\n' "$base_ref"
  printf 'Worktree: %s\n\n' "$worktree_path"

  if [ "${CMUX_WORKTREE_DRY_RUN:-0}" = "1" ]; then
    printf 'Dry run: no worktree was created.\n'
    return 0
  fi

  mkdir -p "$worktree_root" || return 1

  base_remote="${base_ref%%/*}"
  base_branch="${base_ref#*/}"
  if [ "$base_remote" != "$base_ref" ] && git -C "$repo_root" remote get-url "$base_remote" >/dev/null 2>&1; then
    printf 'Refreshing %s...\n' "$base_ref"
    git -C "$repo_root" fetch "$base_remote" "$base_branch" || {
      printf 'Could not refresh %s; no worktree was created.\n' "$base_ref"
      return 1
    }
  fi

  git -C "$repo_root" worktree add -b "$branch" "$worktree_path" "$base_ref" || return 1
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
