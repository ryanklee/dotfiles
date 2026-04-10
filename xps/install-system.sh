#!/usr/bin/env bash
# XPS 15 9500 — system config install script.
# Copies root-owned config files into /etc/ and applies them.
# Must be run with sudo:  sudo ./xps/install-system.sh

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Must be run as root:  sudo $0" >&2
    exit 1
fi

copy() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  $dst"
}

echo "Installing XPS system config..."
echo

echo "── sysctl ──"
copy "$DIR/system/sysctl.d/99-xps-tuning.conf" /etc/sysctl.d/99-xps-tuning.conf
sysctl --system 2>&1 | grep "99-xps" || true

echo
echo "── modprobe (i915 GuC, NVIDIA RTD3) ──"
copy "$DIR/system/modprobe.d/i915-guc.conf" /etc/modprobe.d/i915-guc.conf
copy "$DIR/system/modprobe.d/nvidia-pm.conf" /etc/modprobe.d/nvidia-pm.conf

echo
echo "── udev (NVIDIA runtime PM) ──"
copy "$DIR/system/udev/80-nvidia-pm.rules" /etc/udev/rules.d/80-nvidia-pm.rules
udevadm control --reload-rules

echo
echo "── apt preferences ──"
copy "$DIR/system/apt/99-no-recommends" /etc/apt/apt.conf.d/99-no-recommends
copy "$DIR/system/apt/99-disable-esm-nagging" /etc/apt/apt.conf.d/99-disable-esm-nagging

echo
echo "── journald size cap ──"
copy "$DIR/system/journald.conf.d/size.conf" /etc/systemd/journald.conf.d/size.conf
systemctl restart systemd-journald

echo
echo "── sudoers (NOPASSWD) ──"
if [ ! -f /etc/sudoers.d/rlk-nopasswd ]; then
    printf 'rlk ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/rlk-nopasswd
    chmod 440 /etc/sudoers.d/rlk-nopasswd
    visudo -c
    echo "  /etc/sudoers.d/rlk-nopasswd created"
else
    echo "  /etc/sudoers.d/rlk-nopasswd already present"
fi

echo
echo "── GRUB (not auto-applied — manual review) ──"
echo "  Verify /etc/default/grub contains:"
echo "    GRUB_TIMEOUT=1"
echo "    GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash mem_sleep_default=deep\""
echo "  Then run: update-grub"

echo
echo "── NVIDIA (not auto-applied — uses prime-select) ──"
echo "  Current prime mode: $(prime-select query 2>/dev/null || echo unknown)"
echo "  For intel-only (recommended): prime-select intel && reboot"
echo "  For on-demand (if dGPU needed): prime-select on-demand && reboot"

echo
echo "Done. Reboot to activate modprobe and GRUB changes."
