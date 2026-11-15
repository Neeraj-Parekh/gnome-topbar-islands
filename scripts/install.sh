#!/usr/bin/env bash
# install.sh - install Top Bar Islands into the current user's GNOME Shell.
#
# Copies extension/ to ~/.local/share/gnome-shell/extensions/topbar-islands@nyx,
# installs the helper scripts to ~/.local/bin, and enables the extension.
#
# Options:
#   --no-enable   copy the files but do not enable the extension
#   --overlay     also enable overlay mode (windows use the full height)
#   --help

set -euo pipefail

UUID=topbar-islands@nyx
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
EXT_DIR="$DATA_HOME/gnome-shell/extensions/$UUID"
BIN_DIR="$HOME/.local/bin"

ENABLE=1
OVERLAY=0

for arg in "$@"; do
    case "$arg" in
        --no-enable) ENABLE=0 ;;
        --overlay) OVERLAY=1 ;;
        -h|--help)
            sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

if [ ! -f "$ROOT/extension/metadata.json" ]; then
    echo "error: run this script from a checkout of the repository" >&2
    exit 1
fi

if ! command -v gnome-extensions >/dev/null 2>&1; then
    echo "error: gnome-extensions not found (is this a GNOME session?)" >&2
    exit 1
fi

echo "installing $UUID"
echo "  extension -> $EXT_DIR"
echo "  scripts   -> $BIN_DIR"

gnome-extensions disable "$UUID" >/dev/null 2>&1 || true
mkdir -p "$EXT_DIR" "$BIN_DIR"
cp -a "$ROOT/extension/." "$EXT_DIR/"
install -m 755 "$ROOT/scripts/topbar-mode.sh" "$BIN_DIR/topbar-mode.sh"
install -m 755 "$ROOT/scripts/topbar-overlay.sh" "$BIN_DIR/topbar-overlay.sh"
install -m 755 "$ROOT/scripts/topbar-clock.sh" "$BIN_DIR/topbar-clock.sh"

if [ "$OVERLAY" -eq 1 ]; then
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/topbar-islands"
    touch "${XDG_CONFIG_HOME:-$HOME/.config}/topbar-islands/overlay"
    echo "  overlay   -> on"
fi

if [ "$ENABLE" -eq 1 ]; then
    gnome-extensions enable "$UUID" >/dev/null 2>&1 || true
    echo
    gnome-extensions info "$UUID" 2>/dev/null | grep -E "State|Enabled" || true
fi

cat <<EOF

next steps
  pick a layout : topbar-mode.sh islands
  overlay mode  : topbar-overlay.sh on      (or off / status)
  clock         : topbar-clock.sh hide      (or show / toggle / status)
  layouts       : topbar-mode.sh list

GNOME imports extension JavaScript once per session.  If the extension does
not appear right away, log out and back in (Wayland cannot restart the shell
in place).
EOF
