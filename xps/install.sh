#!/usr/bin/env bash
# XPS 15 9500 — user config install script.
# Symlinks user-owned config from this repo into their expected locations.
# Run from the dotfiles repo root:  ./xps/install.sh
#
# For system-level config (requires sudo), see: ./xps/install-system.sh

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$DIR/.." && pwd)"

link() {
    local src="$1" dst="$2"
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

echo "Installing XPS dotfiles..."
echo

echo "── Shared dotfiles (cross-machine) ──"
link "$REPO/fish-config.fish"     ~/.config/fish/config.fish
link "$REPO/gitconfig"            ~/.gitconfig
link "$REPO/tmux.conf"            ~/.config/tmux/tmux.conf

echo
echo "── XPS-specific user config ──"
link "$DIR/fish-conf.d/99-xps.fish"  ~/.config/fish/conf.d/99-xps.fish
link "$DIR/foot.ini"                 ~/.config/foot/foot.ini
link "$DIR/ssh-config"               ~/.ssh/config
chmod 600 "$DIR/ssh-config"

echo
echo "── Helper scripts (~/bin) ──"
mkdir -p ~/bin
for f in "$DIR"/bin/*; do
    link "$f" ~/bin/"$(basename "$f")"
done

echo
echo "── Systemd user units ──"
mkdir -p ~/.config/systemd/user
link "$DIR/systemd/hapax-mode-refresh.service" ~/.config/systemd/user/hapax-mode-refresh.service
link "$DIR/systemd/hapax-mode-refresh.timer"   ~/.config/systemd/user/hapax-mode-refresh.timer

echo
echo "── Autostart entries ──"
mkdir -p ~/.config/autostart
link "$DIR/autostart/copyq.desktop" ~/.config/autostart/copyq.desktop

echo
echo "── Directories ──"
mkdir -p ~/projects ~/hapax-mnt ~/.cache/hapax

echo
echo "── TPM (tmux plugin manager) ──"
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo "  TPM installed — run prefix+I inside tmux to install plugins"
else
    echo "  TPM already present"
fi

echo
echo "── Systemd user timer ──"
systemctl --user daemon-reload
systemctl --user enable --now hapax-mode-refresh.timer 2>/dev/null || true
echo "  hapax-mode-refresh.timer enabled"

echo
echo "── Shell ──"
if [ "$(basename "$SHELL")" != "fish" ]; then
    echo "  Default shell is not fish. Run: chsh -s /usr/bin/fish"
else
    echo "  Default shell is already fish"
fi

echo
echo "── xdg-user-dirs ──"
echo "enabled=False" > ~/.config/user-dirs.conf
echo "  Auto-creation of Desktop/Music/etc disabled"

echo
echo "Done."
echo "For system-level config (sysctl, modprobe, udev, apt, grub): ./xps/install-system.sh"
echo "For GNOME keybindings and gsettings: see README.md § GNOME Settings"
