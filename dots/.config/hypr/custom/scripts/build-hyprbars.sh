#!/usr/bin/env bash
# Build hyprbars for the RUNNING Hyprland version and install it to custom/plugins/.
# Needed after every Hyprland update (plugins are ABI-locked to the exact Hyprland build).
# Uses the commit pins in hyprland-plugins/hyprpm.toml, the same way hyprpm does.
set -euo pipefail
DEST="$HOME/.config/hypr/custom/plugins"
SRC="${XDG_CACHE_HOME:-$HOME/.cache}/hyprland-plugins-src"

for dep in git make pkg-config jq g++; do command -v "$dep" >/dev/null || { echo "missing: $dep"; exit 1; }; done
pkg-config --exists hyprland || { echo "Hyprland headers not found (pkg-config hyprland). On Arch they ship with the hyprland package; check: pacman -Ql hyprland | grep include | head"; exit 1; }

HL_COMMIT=$(hyprctl version -j | jq -r .commit)
HL_TAG=$(hyprctl version -j | jq -r .tag)
echo "Hyprland: $HL_TAG ($HL_COMMIT)"

if [ -d "$SRC/.git" ]; then git -C "$SRC" fetch -q origin; else git clone -q https://github.com/hyprwm/hyprland-plugins "$SRC"; fi
git -C "$SRC" checkout -q origin/HEAD 2>/dev/null || git -C "$SRC" checkout -q origin/main

# Find the plugins commit pinned to our Hyprland commit (if pinned); else use latest main
PIN=$(grep -oE "\[\"${HL_COMMIT}\", *\"[0-9a-f]+\"\]" "$SRC/hyprpm.toml" | grep -oE '"[0-9a-f]+"\]' | tr -d '"]' || true)
if [ -n "$PIN" ]; then echo "Using pinned hyprland-plugins commit $PIN"; git -C "$SRC" checkout -q "$PIN"
else echo "No pin for this Hyprland commit; building latest hyprland-plugins main"; fi

make -C "$SRC/hyprbars" all
mkdir -p "$DEST"
install -m755 "$SRC/hyprbars/hyprbars.so" "$DEST/hyprbars.so"
echo "Installed $DEST/hyprbars.so"
echo "Run: hyprctl reload   (or press Super+B)"
