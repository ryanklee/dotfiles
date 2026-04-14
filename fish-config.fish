# Source cachyos config only in interactive shells.
# done.fish (sourced by cachyos-config) calls `exit` for non-interactive shells,
# which kills shells spawned by tools like Claude Code.
if status is-interactive
    # Guard the source for cross-distro portability — file exists only on CachyOS.
    set -l cachyos_cfg /usr/share/cachyos-fish-config/cachyos-config.fish
    test -r $cachyos_cfg; and source $cachyos_cfg
end
fish_add_path -g ~/go/bin

# Dev tooling paths
fish_add_path -g ~/.cargo/bin
fish_add_path -g ~/.local/bin

# Defaults
set -gx EDITOR micro
set -gx VISUAL micro
set -gx BROWSER google-chrome-stable
set -gx TERMINAL foot

# Wayland env vars moved to ~/.config/hypr/hyprland.conf
# (avoids forcing Wayland for Qt/Mozilla apps in TTY or non-Hyprland sessions)

# LLM tools
set -gx LITELLM_BASE_URL http://localhost:4000
# LITELLM_API_KEY loaded via direnv (.envrc) — pass call removed
# because GPG/keyboxd hangs can break all shell init

# Quick aliases
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias nv='nvim'
alias j='journalctl --no-pager -e'
alias ju='journalctl --user --no-pager -e'
alias hc='hyprctl'
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias wp='wpctl status'
alias gpu='nvidia-smi'

# Quick directory jumps
alias proj='cd ~/projects'

# Default directory for interactive shells
if status is-interactive
    cd ~/projects
end
alias llms='cd ~/llm-stack'

# CUDA / GPU compute — pin interactive shells to the RTX 3090 by UUID so a
# topology change (adding/removing cards, BIOS reenumeration) doesn't swap
# this out from under interactive Python work.
set -gx CUDA_DEVICE_ORDER PCI_BUS_ID
set -gx CUDA_VISIBLE_DEVICES GPU-2d94387f-adb2-51b2-b40f-0c576022d1a9
set -gx PYTORCH_CUDA_ALLOC_CONF expandable_segments:True,garbage_collection_threshold:0.8
