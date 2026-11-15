#!/usr/bin/env bash
# topbar-clock.sh - show or hide the date and time in the right island.
#
# hide   : hide the date/time cluster; a chevron button stays in the island
# show   : show the date/time cluster again
# toggle : flip the current state
# status : report the flag and whether the extension is active
#
# The flag is ~/.config/topbar-islands/clock-hidden.  The running extension
# watches that directory, so a change applies immediately.  The same state is
# toggled by the chevron button at the left edge of the right island.

set -u

UUID=topbar-islands@nyx
FLAG="${XDG_CONFIG_HOME:-$HOME/.config}/topbar-islands/clock-hidden"

usage() {
    echo "usage: $(basename "$0") {show|hide|toggle|status}" >&2
}

is_hidden() {
    [ -f "$FLAG" ] && [ "$(tr -d '[:space:]' < "$FLAG")" = "1" ]
}

extension_state() {
    if command -v gnome-extensions >/dev/null 2>&1; then
        gnome-extensions info "$UUID" 2>/dev/null |
            awk -F': *' '/State/ { print $2; exit }'
    fi
}

set_hidden() {
    mkdir -p "$(dirname "$FLAG")"
    if [ "$1" -eq 1 ]; then
        printf '1\n' > "$FLAG"
    else
        printf '0\n' > "$FLAG"
    fi
}

case "${1:-status}" in
    hide)
        set_hidden 1
        echo "clock: hidden"
        ;;
    show)
        set_hidden 0
        echo "clock: shown"
        ;;
    toggle)
        if is_hidden; then
            set_hidden 0
            echo "clock: shown"
        else
            set_hidden 1
            echo "clock: hidden"
        fi
        ;;
    status)
        if is_hidden; then
            echo "flag: hidden"
        else
            echo "flag: shown"
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
