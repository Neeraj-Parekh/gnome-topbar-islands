#!/usr/bin/env bash
# topbar-overlay.sh - let windows use the full screen height under the bar.
#
# on     : windows may use the full height; the islands float above them and
#          clicks in the empty middle reach the window below.
# off    : the panel reserves the top strip again and maximized windows start
#          below the bar.
# status : report the flag and whether the extension is active.
#
# The flag is ~/.config/topbar-islands/overlay.  The running extension watches
# that directory, so a change applies immediately; no reload and no shell
# unsafe mode are needed.  If the extension is not enabled, the flag is
# applied the next time it is enabled.

set -u

UUID=topbar-islands@nyx
FLAG="${XDG_CONFIG_HOME:-$HOME/.config}/topbar-islands/overlay"

usage() {
    echo "usage: $(basename "$0") {on|off|status}" >&2
}

extension_state() {
    if command -v gnome-extensions >/dev/null 2>&1; then
        gnome-extensions info "$UUID" 2>/dev/null |
            awk -F': *' '/State/ { print $2; exit }'
    fi
}

case "${1:-status}" in
    on)
        mkdir -p "$(dirname "$FLAG")"
        touch "$FLAG"
        echo "top bar overlay: on"
        echo "  windows use the full height; the islands float above them"
        ;;
    off)
        rm -f "$FLAG"
        echo "top bar overlay: off"
        echo "  the panel reserves the top strip again"
        ;;
    status)
        if [ -e "$FLAG" ]; then
            echo "flag: on"
        else
            echo "flag: off"
        fi
        state=$(extension_state)
        if [ -n "$state" ]; then
            echo "extension: $state"
        else
            echo "extension: not installed"
        fi
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        usage
        exit 2
        ;;
esac
