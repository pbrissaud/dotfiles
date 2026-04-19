# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal dotfiles repo for macOS. It manages:
- Homebrew package installation (from `packages.txt`)
- Config file syncing between `assets/` and `$HOME` (bidirectional)
- Git hooks setup

## Key scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | Install packages + copy `assets/` → `$HOME` |
| `export.sh` | Copy `$HOME` → `assets/` (then optionally commit/push) |
| `hack/install-hooks.sh` | Install git pre-commit hook |
| `hack/write-package-list.sh` | Regenerate `packages.txt` from `# pkg:` comments |

## Package management

`packages.txt` is **auto-generated** — do not edit it manually. To add a Homebrew package, add a comment `# pkg: <name>` anywhere in the `assets/` tree (or in any tracked config file). The pre-commit hook regenerates `packages.txt` automatically on each commit.

## Config file sync (`assets/`)

The `assets/` directory mirrors the structure of `$HOME`. For example:
- `assets/.zshrc` → `~/.zshrc`
- `assets/.config/starship.toml` → `~/.config/starship.toml`
- `assets/.config/ghostty/` → `~/.config/ghostty/`

`assets/.zsh_override.zsh` is in `NEVER_SYNC_FILES` — it is never copied in either direction (intended for machine-local overrides).

## Shared library

`lib/common.sh` is sourced by both `install.sh` and `export.sh`. It provides conflict detection (hash comparison), interactive diff display, backup creation, and result tracking. The `SYNC_MODE` variable (set to `"install"` or `"export"`) controls which options appear in prompts.
