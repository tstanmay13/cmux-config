#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$HOME/.config/cmux-config-backups/$stamp"

link_config() {
  local source_path="$1"
  local target_path="$2"
  local relative_target="${target_path#"$HOME"/}"

  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    echo "  already linked: $target_path"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    mkdir -p "$backup_root/$(dirname "$relative_target")"
    cp -a "$target_path" "$backup_root/$relative_target"
    echo "  backed up: $target_path"
  fi

  rm -f "$target_path"
  ln -s "$source_path" "$target_path"
  echo "  linked: $target_path -> $source_path"
}

echo "Installing cmux configuration from $repo_dir"
link_config "$repo_dir/cmux/cmux.json" "$HOME/.config/cmux/cmux.json"
link_config "$repo_dir/ghostty/config" "$HOME/.config/ghostty/config"

if command -v cmux >/dev/null 2>&1; then
  cmux config doctor

  if command -v codex >/dev/null 2>&1; then
    cmux hooks codex install --yes
  fi

  if cmux ping >/dev/null 2>&1; then
    cmux reload-config
  else
    echo "cmux is not running; it will load the configuration next launch."
  fi
else
  echo "cmux is not installed; install it and run this script again for hooks."
fi

if [ -d "$backup_root" ]; then
  echo "Backups: $backup_root"
fi
echo "Done."
