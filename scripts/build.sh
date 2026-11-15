#!/usr/bin/env bash
# build.sh - package the extension as an installable zip.
#
# The archive contains metadata.json, extension.js, stylesheet.css and
# presets/ at its top level, which is the layout that
# `gnome-extensions install dist/topbar-islands@nyx.zip` expects.
#
# Output: dist/topbar-islands@nyx.zip

set -euo pipefail

UUID=topbar-islands@nyx
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIST="$ROOT/dist"
STAGE=$(mktemp -d)

cleanup() {
    rm -rf "$STAGE"
}
trap cleanup EXIT

if ! command -v zip >/dev/null 2>&1; then
    echo "error: zip is required" >&2
    exit 1
fi

cp -a "$ROOT/extension/." "$STAGE/"

# Never ship editor or backup files.
find "$STAGE" -name '.*' -delete
find "$STAGE" -name '*~' -delete
find "$STAGE" -name '*.bak' -delete

mkdir -p "$DIST"
rm -f "$DIST/$UUID.zip"

(cd "$STAGE" && zip -qr "$DIST/$UUID.zip" .)

echo "built $DIST/$UUID.zip"
unzip -l "$DIST/$UUID.zip"
