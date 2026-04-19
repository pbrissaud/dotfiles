# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal dotfiles repo for macOS. It manages:
- Package installation via Homebrew (`Brewfile`), mise, and curl-based installers
- Config file syncing between `assets/` and `$HOME` (bidirectional, copy or symlink)
- Git hooks setup

## Key scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | Install packages + sync `assets/` → `$HOME` |
| `install.sh --symlink` | Same, but create symlinks instead of copies |
| `install.sh --yes` | Non-interactive mode (auto-confirm all prompts) |
| `export.sh` | Sync `$HOME` → `assets/` (then optionally commit/push) |
| `hack/install-hooks.sh` | Install git pre-commit hook |
| `hack/write-package-list.sh` | Regenerate `Brewfile`, `curl-installs.txt`, `assets/.config/mise/config.toml` from `# pkg:` comments |

## Package management

`Brewfile`, `curl-installs.txt`, and `assets/.config/mise/config.toml` are **auto-generated** — do not edit them manually. To declare a package, annotate any file in `assets/` with a typed `# pkg:` comment:

| Annotation | Effect |
|------------|--------|
| `# pkg:brew=bat` | Homebrew formula |
| `# pkg:cask=ghostty` | Homebrew cask |
| `# pkg:tap=homebrew/cask-fonts` | Homebrew tap |
| `# pkg:mas=AppName:1234567` | Mac App Store (requires `mas`) |
| `# pkg:mise=node@22` | mise language tool |
| `# pkg:curl=claude:https://claude.ai/install.sh` | curl-based installer (skipped if binary exists) |

Multiple packages on one line: `# pkg:brew=fzf,bat`

**The scanner only reads files inside `assets/`** — pkg comments in scripts or documentation are ignored.

The pre-commit hook regenerates all three files automatically on each commit.

## Config file sync (`assets/`)

The `assets/` directory mirrors the structure of `$HOME`. For example:
- `assets/.zshrc` → `~/.zshrc`
- `assets/.config/starship.toml` → `~/.config/starship.toml`
- `assets/.config/ghostty/` → `~/.config/ghostty/`

`assets/.zsh_override.zsh` is in `NEVER_SYNC_FILES` — it is never copied or linked (intended for machine-local overrides).

## Shared library

`lib/common.sh` is sourced by both `install.sh` and `export.sh`. It provides conflict detection (hash comparison), interactive diff display, backup creation, symlink support, and result tracking. Key env vars:
- `SYNC_MODE` — `"install"` or `"export"`, controls prompt options
- `SYNC_SYMLINK` — `"1"` when `--symlink` is passed to `install.sh`
- `YES_MODE` — `"1"` when `--yes` is passed, auto-confirms all prompts
