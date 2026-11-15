#!/usr/bin/env bash
# topbar-mode.sh - switch the GNOME top bar between layouts and reload it.
#
# Modes:
#   islands          two flush translucent islands, left and right, touching
#                    the top and side screen edges, with a fully transparent
#                    middle (alpha 0.55, readable on bright wallpaper)
#   islands-soft     same flush islands at alpha 0.38, closer to a light tint
#   islands-floating the earlier floating version with 3px/8px margins
#   strip            a single full-width translucent strip
#
# Presets live next to the extension in presets/*.css.  Switching copies the
# preset over stylesheet.css and reloads the extension, which takes about a
# second and does not restart GNOME Shell.

set -u

UUID=topbar-islands@nyx
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID"
PRESETS="$EXT_DIR/presets"

usage() {
    echo "usage: $(basename "$0") {islands|islands-soft|islands-floating|strip|list}" >&2
}

case "${1:-list}" in
    islands|islands-soft|islands-floating|strip)
        preset="$PRESETS/$1.css"
        if [ ! -f "$preset" ]; then
            echo "missing preset: $preset" >&2
            exit 1
        fi
        cp -a "$preset" "$EXT_DIR/stylesheet.css"
        gnome-extensions disable "$UUID" >/dev/null 2>&1
        sleep 0.5
        gnome-extensions enable "$UUID" >/dev/null 2>&1
        sleep 1
        echo "top bar mode: $1"
        gnome-extensions info "$UUID" 2>/dev/null | grep -E "State" || true
        ;;
    list)
        for f in "$PRESETS"/*.css; do
            [ -e "$f" ] || continue
            printf '%s\n' "$(basename "$f" .css)"
        done
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        usage
        exit 2
        ;;
esac
