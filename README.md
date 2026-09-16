# cmux-config

My personal [cmux](https://cmux.com/) setup for running Claude Code and Codex beside browser previews, documentation, tests, and logs.

## What this config does

- Keeps workspaces in a stable order and places new workspaces after the current one.
- Shows concise Git branch, pull request, port, progress, and agent state in the sidebar.
- Sends permission and completed-turn alerts through cmux, with pane rings and a Dock badge.
- Enables Claude Code integration and installs cmux's maintained Codex lifecycle hooks.
- Restores supported agent sessions after relaunch.
- Opens terminal links, pull requests, and local ports in cmux's embedded browser at 115% zoom.
- Uses side-by-side diffs and cmux's Markdown viewer.
- Keeps terminal text at 14pt, sidebar text at 15pt, and surface tabs at 13pt.
- Creates an isolated STLabs Git worktree when starting a workspace with `Cmd-N`.

No tokens, credentials, generated hook files, session data, or machine IDs are stored here.

## Install on a new Mac

Install [cmux](https://cmux.com/docs/getting-started), Codex, and Claude Code first. For the complete Catppuccin theme and cursor shaders, install [ghostty-config](https://github.com/tstanmay13/ghostty-config) before this repository.

```bash
mkdir -p ~/Documents/personal
git clone https://github.com/tstanmay13/cmux-config.git ~/Documents/personal/cmux-config
cd ~/Documents/personal/cmux-config
./install.sh
./verify.sh
```

The installer creates timestamped backups under `~/.config/cmux-config-backups/`, then installs the tracked files as follows:

```text
cmux/cmux.json  copied to ~/.config/cmux/cmux.json
ghostty/config  linked to ~/.config/ghostty/config
```

`cmux.json` is copied deliberately. cmux caches the metadata of that exact path, so a file symlink can hide changes made to its target even after a configuration reload. The repository remains the source of truth; rerun `./install.sh` after changing or pulling the config.

It validates the cmux config, installs the maintained Codex hooks, and reloads a running cmux app. Claude Code integration is enabled directly in `cmux.json` and is injected by cmux's Claude wrapper.

## Daily shortcuts

| Shortcut | Action |
| --- | --- |
| `Cmd-N` | Prompt for a task and create a new STLabs worktree workspace |
| `Cmd-T` | New surface in the focused pane |
| `Cmd-D` | Split right |
| `Cmd-Shift-D` | Split down |
| `Cmd-Option-Arrows` | Focus a neighboring pane |
| `Cmd-Shift-[` / `]` | Previous or next surface |
| `Cmd-1` through `9` | Jump to a workspace |
| `Cmd-Shift-L` | Open a browser split |
| `Cmd-Shift-Return` | Zoom or restore the focused pane |
| `Cmd-I` | Open notifications |
| `Cmd-Shift-U` | Jump to the newest unread alert |
| `Cmd-Shift-P` | Open the command palette |
| `Cmd-Shift-Option-T` | Reopen a closed workspace |
| `Cmd-Shift-,` | Reload configuration |

The main workspace sidebar stays on the left. `Cmd-Option-B` toggles cmux's auxiliary right sidebar, and `Cmd-B` hides or shows the workspace sidebar.

## Worktree workspaces

From anywhere inside the STLabs repository, press `Cmd-N` and enter a short task name such as `Ticket search timeout`. The helper normalizes that text to `ticket-search-timeout`, displays the resolved branch and path, and immediately creates:

```text
branch:   tanmaysingh/ticket-search-timeout
base:     origin/main
worktree: ~/Documents/stlabs/worktrees/ticket-search-timeout
```

The new workspace stays attached to its normal interactive shell, changes into the worktree, and is renamed to the task slug. Branch or path collisions are refused. Worktrees are never removed automatically.

Outside the STLabs repository, `Cmd-N` creates a normal workspace in the inherited directory. The New Workspace menu also includes **Blank Workspace** when you intentionally do not want a worktree.

Remove a finished worktree manually after its changes are committed or otherwise preserved:

```bash
git worktree list
git worktree remove ~/Documents/stlabs/worktrees/<task>
git branch -d tanmaysingh/<task>
```

## Useful commands

```bash
cmux /path/to/repository
cmux tree
cmux top --processes
cmux diff --branch --base origin/main
cmux markdown README.md
cmux browser open http://localhost:3000
cmux hooks codex install --yes
cmux reload-config
```

## Updating the saved setup

The Ghostty file is linked into this checkout. The cmux file is a managed copy, so rerun the installer after editing or pulling it. Commit and push changes to carry them to other Macs.

```bash
./install.sh
cmux config doctor
./verify.sh
git add cmux ghostty scripts install.sh verify.sh README.md
git commit -m "Update cmux configuration"
git push
```

## References

- [cmux configuration](https://cmux.com/docs/configuration)
- [cmux keyboard shortcuts](https://cmux.com/docs/keyboard-shortcuts)
- [cmux agent integrations](https://github.com/manaflow-ai/cmux/blob/main/docs/agent-hooks.md)
- [cmux browser automation](https://cmux.com/docs/browser-automation)
- [Ghostty configuration reference](https://ghostty.org/docs/config/reference)
