# Dotfiles

Personal macOS configuration files managed with bash scripts and Homebrew.

## Setup

```bash
./install.sh   # Install packages + copy configs to $HOME
```

## Sync configs back to repo

```bash
./export.sh    # Copy $HOME configs → assets/, then commit/push
```

## Add a Homebrew package

Add a `# pkg: <name>` comment anywhere in `assets/`. The pre-commit hook regenerates `packages.txt` automatically.

## Structure

- `assets/` — config files mirroring `$HOME` structure
- `packages.txt` — auto-generated Homebrew package list (do not edit manually)
- `lib/common.sh` — shared functions (conflict detection, diff, backup)
- `hack/` — git hook installer and package list generator