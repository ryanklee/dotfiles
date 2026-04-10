# XPS 15 9500 — Remote Dev Client for hapax-podium

Dell XPS 15 9500, Ubuntu 26.04 "resolute", GNOME 50 on Wayland.
Thin client for remote development on hapax-podium via Claude Code.

## Architecture

All development happens on **hapax-podium** (CachyOS, Hyprland, RTX 3090).
Claude Code runs there in a persistent dual-pane tmux session named `work`.
This laptop is a window into that:

- **Terminal**: foot → mosh → tmux attach (or SSH fallback on flaky networks)
- **Dashboards**: Chrome → tailscale-serve HTTPS URLs
- **Visual observation**: waypipe for individual Wayland apps, RustDesk for full desktop
- **Secrets**: `hapax-pass` SSH wrapper (no local GPG/pass install)
- **Filesystem**: sshfs mount at `~/hapax-mnt/` when needed

## Quick Reference

### Commands (fish abbreviations)

| Abbrev | Command | Description |
|--------|---------|-------------|
| `cc` / `hw` | `hapax-work` | Mosh into hapax-podium's persistent tmux `work` session |
| `hs` | `hapax-status` | Tailnet + SSH + tmux health check with latency |
| `hl <svc>` | `hapax-logs` | Tail a remote systemd user service's journal |
| `hp <key>` | `hapax-pass` | Fetch secret from remote pass store |
| `dash <svc>` | — | Open dashboard in Chrome (grafana langfuse prom webui n8n logos) |
| `wpipe <cmd>` | — | Forward a hapax-podium Wayland app to this display |
| `hapax-mount` | — | sshfs mount hapax-podium:~ at ~/hapax-mnt/ |
| `hapax-unmount` | — | Unmount sshfs |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Super+Return | foot → hapax-work (primary daily driver) |
| Ctrl+Alt+T | foot (local terminal) |
| Super+V | CopyQ clipboard history |
| Print | Flameshot screenshot |
| Ctrl+= / Ctrl+- / Ctrl+0 | foot font zoom (per-window) |

## What's Installed

### Packages (apt)

```
fish foot tmux mosh waypipe micro gh git git-delta
fzf ripgrep fd-find bat eza zoxide direnv atuin
lm-sensors smartmontools powertop btop nvme-cli intel-gpu-tools
wl-clipboard gnome-tweaks gnome-shell-extension-manager sshfs
copyq kdeconnect google-chrome-stable rustdesk flameshot
flatpak gnome-software-plugin-flatpak
```

### Font

JetBrainsMono Nerd Font (full family) installed to `~/.local/share/fonts/JetBrainsMono-NF/`.
foot uses it at size 13 with Gruvbox Hard Dark colorscheme.

### Tailscale

Intel-only GPU mode (`prime-select intel`). Node signed into tailnet with lock;
this XPS is a trusted tailnet-lock signer.

## System-Level Config

Files tracked in `xps/system/`, installed by `sudo ./xps/install-system.sh`:

| File | Purpose |
|------|---------|
| `sysctl.d/99-xps-tuning.conf` | swappiness=10, vfs_cache_pressure=50, inotify 524k, dirty ratios for NVMe |
| `modprobe.d/i915-guc.conf` | i915 GuC+HuC for HW video decode + power |
| `modprobe.d/nvidia-pm.conf` | NVIDIA RTD3 (moot when prime-select intel) |
| `udev/80-nvidia-pm.rules` | NVIDIA runtime PM auto (moot when prime-select intel) |
| `apt/99-no-recommends` | APT Install-Recommends false |
| `apt/99-disable-esm-nagging` | Silence Ubuntu Pro spam |
| `journald.conf.d/size.conf` | Journal cap 500M / 7-day retention |

### Not tracked (manual)

- `/etc/sudoers.d/rlk-nopasswd` — `rlk ALL=(ALL) NOPASSWD:ALL` (created by install-system.sh if missing)
- `/etc/default/grub` — `GRUB_TIMEOUT=1`, `mem_sleep_default=deep` in CMDLINE
- `prime-select intel` — NVIDIA dGPU disabled, Intel iGPU only

## GNOME Settings (gsettings, not tracked as files)

Applied during initial setup, persisted in dconf (`~/.config/dconf/user`):

```bash
# Keyboard
gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

# Trackpad
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'

# Display
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 22.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 6.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature "uint32 2800"

# Power
powerprofilesctl set balanced

# Default browser
xdg-settings set default-web-browser google-chrome.desktop

# Screenshot (GNOME default disabled, flameshot replaces it)
gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]"

# Custom keybindings (see keyboard shortcuts table above)
# Set via gsettings org.gnome.settings-daemon.plugins.media-keys custom-keybindings
```

## Rebuild From Scratch

1. Fresh Ubuntu install
2. Set up passwordless sudo: `echo "rlk ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/rlk-nopasswd && sudo chmod 440 /etc/sudoers.d/rlk-nopasswd`
3. Install tailscale: `curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up`
4. Sign the node from hapax-podium: `tailscale lock sign <nodekey> <tlpub>`
5. Generate SSH key: `ssh-keygen -t ed25519 -N ""` and add pubkey to hapax-podium's `~/.ssh/authorized_keys`
6. Clone dotfiles: `git clone https://github.com/ryanklee/dotfiles ~/dotfiles && cd ~/dotfiles && git checkout main`
7. Install shared + XPS config: `./xps/install.sh`
8. Install system config: `sudo ./xps/install-system.sh`
9. Install packages: `sudo apt install -y fish foot tmux mosh waypipe micro gh git-delta fzf ripgrep fd-find bat eza zoxide direnv atuin lm-sensors smartmontools powertop btop nvme-cli intel-gpu-tools wl-clipboard gnome-tweaks gnome-shell-extension-manager sshfs copyq kdeconnect flatpak gnome-software-plugin-flatpak`
10. Install Chrome: `curl -fsSL -o /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y /tmp/chrome.deb`
11. Install JetBrainsMono Nerd Font: `curl -fsSL -o /tmp/jbm.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz && mkdir -p ~/.local/share/fonts/JetBrainsMono-NF && tar -xf /tmp/jbm.tar.xz -C ~/.local/share/fonts/JetBrainsMono-NF/ && fc-cache -f`
12. Install flameshot, RustDesk (see session notes for RustDesk .deb URL)
13. Disable NVIDIA: `sudo prime-select intel`
14. Apply GNOME settings (see § GNOME Settings above)
15. `sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`
16. `chsh -s /usr/bin/fish`
17. `gh auth login --git-protocol https --web`
18. `gh ssh-key add ~/.ssh/id_ed25519.pub --title "rlk-xps-15-9500"`
19. Reboot

## Hardware Notes

- **Display**: 1920x1200 FHD+ (no fractional scaling needed, text-scaling-factor=1.0)
- **GPU**: Intel UHD (CometLake iGPU) + NVIDIA GTX 1650 Ti Mobile. NVIDIA disabled via `prime-select intel`. Reversible: `sudo prime-select on-demand && reboot`.
- **Battery**: Dell charge threshold supported (`/sys/class/power_supply/BAT0/charge_control_{start,end}_threshold`). Currently 50–90%.
- **Suspend**: Deep (S3) via `mem_sleep_default=deep` kernel param. If resume is unreliable, remove the param from GRUB and `update-grub`.
- **Storage**: Samsung PM981a 512GB + Fikwot FN955 1TB. Both SMART healthy. fstrim.timer weekly.
- **RAM**: 14GB (16GB physical, ~14GB usable).
- **Firmware**: BIOS 1.40.0, all firmware up to date via fwupd.
