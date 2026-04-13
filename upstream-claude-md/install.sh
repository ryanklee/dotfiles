#!/usr/bin/env bash
# install.sh — symlink upstream-clone CLAUDE.md files into their working dirs.
#
# These CLAUDE.md files live in dotfiles (this directory) but are read by Claude
# Code from inside the upstream-tracked working dirs (atlas-voice-training,
# tabbyAPI). The originals would be untracked-and-uncommitted in those repos,
# which is fragile across reclones. Symlinking from a dotfiles-tracked source
# makes them survivable.
#
# This script also adds the symlink path to each repo's .git/info/exclude so
# git status does not show them as untracked.
#
# Idempotent: re-running is safe.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

declare -A targets=(
    ["atlas-voice-training"]="atlas-voice-training-CLAUDE.md"
    ["tabbyAPI"]="tabbyAPI-CLAUDE.md"
)

for repo in "${!targets[@]}"; do
    src="$DOTFILES_DIR/${targets[$repo]}"
    dst="$PROJECTS_DIR/$repo/CLAUDE.md"
    exclude="$PROJECTS_DIR/$repo/.git/info/exclude"

    if [[ ! -f "$src" ]]; then
        printf 'install: source missing: %s\n' "$src" >&2
        exit 1
    fi
    if [[ ! -d "$PROJECTS_DIR/$repo" ]]; then
        printf 'install: target repo missing: %s — skipping\n' "$PROJECTS_DIR/$repo" >&2
        continue
    fi

    # If a real file (not a symlink) is in the way, refuse to clobber it.
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        printf 'install: %s exists and is not a symlink — refusing to clobber\n' "$dst" >&2
        printf '  resolve manually: `mv %s %s.bak` then re-run\n' "$dst" "$dst" >&2
        exit 1
    fi

    ln -snf "$src" "$dst"
    printf 'install: %s -> %s\n' "$dst" "$src"

    if [[ -f "$exclude" ]] && ! grep -qxF 'CLAUDE.md' "$exclude"; then
        printf 'CLAUDE.md\n' >> "$exclude"
        printf 'install: appended CLAUDE.md to %s\n' "$exclude"
    fi
done
