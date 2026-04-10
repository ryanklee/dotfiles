# XPS-specific fish overrides (machine-local, NOT in ~/dotfiles repo)
#
# Fish load order: conf.d/*.fish loads BEFORE config.fish.

# ── Ubuntu package naming quirks ──────────────────────────────────────
# Ubuntu ships fd as fdfind and bat as batcat to avoid binary name clashes.
if not command -sq fd; and command -sq fdfind
    alias fd=fdfind
end
if not command -sq bat; and command -sq batcat
    alias bat=batcat
end

# ── ~/bin in PATH ─────────────────────────────────────────────────────
fish_add_path -g ~/bin

# ── Tool hooks (atuin, direnv) ────────────────────────────────────────
# Ctrl-R history search via atuin, .envrc loading via direnv.
# Safe to call: the hooks no-op if their config is absent.
if command -sq atuin
    atuin init fish --disable-up-arrow | source
end
if command -sq direnv
    direnv hook fish | source
end

# ── XPS-only abbreviations ────────────────────────────────────────────
# Daily driver — launch remote Claude Code session in persistent tmux
abbr -a cc 'hapax-work'
abbr -a hw 'hapax-work'
abbr -a hs 'hapax-status'
abbr -a hl 'hapax-logs'
abbr -a hp 'hapax-pass'

# ── Dashboard opener ──────────────────────────────────────────────────
# Opens a hapax-podium dashboard in Chrome via the tailnet-serve HTTPS URLs.
# Uses google-chrome-stable directly rather than xdg-open so we don't
# depend on the xdg default-browser setting being correct.
function dash --description "Open a hapax-podium dashboard in Chrome"
    set -l base "https://hapax-podium.tailf9491.ts.net"
    if test (count $argv) -eq 0
        echo "Usage: dash <grafana|langfuse|prometheus|openwebui|n8n|logos>" >&2
        return 1
    end
    set -l url ""
    switch $argv[1]
        case grafana
            set url $base:3001/
        case langfuse
            set url $base:3000/
        case prometheus prom
            set url $base:9090/
        case openwebui webui
            set url $base:8080/
        case n8n
            set url $base:5678/
        case logos
            set url $base:8443/
        case '*'
            echo "Unknown dashboard: $argv[1]" >&2
            echo "Known: grafana langfuse prometheus openwebui n8n logos" >&2
            return 1
    end
    google-chrome-stable "$url" &
    disown
end

# ── Waypipe wrapper ───────────────────────────────────────────────────
# Run a hapax-podium Wayland app on this XPS display.
# e.g. wpipe foot     (get a remote foot terminal window)
#      wpipe nautilus (browse hapax-podium's filesystem graphically)
function wpipe --description "Run a hapax-podium Wayland app on this display via waypipe"
    if test (count $argv) -eq 0
        echo "Usage: wpipe <remote-app-cmd ...>" >&2
        return 1
    end
    waypipe ssh hapax -- $argv
end

# ── Custom fish greeting (cheat sheet for this machine's role) ────────
set -g fish_greeting "
 XPS 15 — remote dev client for hapax-podium

   cc / hw              Start/attach remote Claude Code (mosh + tmux)
   hs                   hapax-status  (tailnet / ssh / tmux check)
   hl <svc> [-f]        hapax-logs    (tail remote systemd journal)
   hp <entry>           hapax-pass    (fetch secret from remote pass)
   dash <svc>           Dashboard in Chrome: grafana langfuse prom webui n8n logos
   wpipe <app>          Forward a hapax-podium Wayland app here
   hapax-mount/unmount  sshfs mount hapax-podium ~/hapax-mnt

 Keys: Super+Ret=hapax  Ctrl+Alt+T=local  Super+V=clipboard  Print=screenshot
"
