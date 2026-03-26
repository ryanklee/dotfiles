#!/usr/bin/env bash
# Symlink dotfiles to their expected locations.
# Run from the dotfiles repo root: ./install.sh

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$DIR/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    echo "BACKUP: $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -s "$src" "$dst"
  echo "  $dst → $src"
}

echo "Installing dotfiles..."
link fish-config.fish          ~/.config/fish/config.fish
link gitconfig                 ~/.gitconfig
link tmux.conf                 ~/.config/tmux/tmux.conf
link hypr/hyprland.conf        ~/.config/hypr/hyprland.conf
link hypr/hypridle.conf        ~/.config/hypr/hypridle.conf
link hypr/hyprlock.conf        ~/.config/hypr/hyprlock.conf
link hypr/hyprlock-research.conf ~/.config/hypr/hyprlock-research.conf
link hypr/hyprlock-rnd.conf    ~/.config/hypr/hyprlock-rnd.conf
link hypr/hyprpaper.conf       ~/.config/hypr/hyprpaper.conf
link waybar/config.jsonc       ~/.config/waybar/config.jsonc
link waybar/style.css          ~/.config/waybar/style.css
link waybar/style-research.css ~/.config/waybar/style-research.css
link waybar/style-rnd.css      ~/.config/waybar/style-rnd.css
link workspace-CLAUDE.md       ~/projects/CLAUDE.md
echo "Done."
