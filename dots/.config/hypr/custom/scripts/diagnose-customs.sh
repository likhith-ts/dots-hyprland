#!/usr/bin/env bash
# Read-only diagnostic: finds where customizations went after an upstream sync/install,
# and gathers quickshell crash info. Changes nothing. Writes a report to ~/customs-diagnose-<date>.txt
#
# Usage: diagnose-customs.sh [path-to-local-dots-hyprland-repo]

REPO="${1:-}"
if [ -z "$REPO" ]; then
    for c in ~/dotfiles/dots-hyprland ~/dots-hyprland ~/.cache/dots-hyprland ~/Downloads/dots-hyprland; do
        [ -d "$c/.git" ] && { REPO="$c"; break; }
    done
fi
OUT=~/customs-diagnose-$(date +%Y%m%d-%H%M%S).txt
C=~/.config
exec > >(tee "$OUT") 2>&1

h() { printf '\n========== %s ==========\n' "$1"; }
run() { echo "\$ $*"; eval "$@" 2>&1 | head -n "${LIMIT:-60}"; }

h "System"
run 'hyprctl version | head -3'
run 'pacman -Q hyprland quickshell quickshell-git illogical-impulse-quickshell-git 2>/dev/null'
run 'qs --version'
echo "Upstream-pinned quickshell commit: 4f508be500dea6e5732cc3d50382a0048b17e7b1"

h "Local repo: $REPO"
if [ -n "$REPO" ]; then
    run "git -C '$REPO' status -sb | head -20"
    run "git -C '$REPO' log --oneline -5"
    run "git -C '$REPO' stash list"
    run "git -C '$REPO' branch -a"
fi

h "hypr/custom (live) — installer skips this dir if it already exists"
run "ls -la $C/hypr/custom $C/hypr/custom/scripts"
[ -n "$REPO" ] && run "diff -rq '$REPO/dots/.config/hypr/custom' $C/hypr/custom"

h "Hyprland config errors / custom binds loaded"
run 'hyprctl configerrors'
run "hyprctl binds -j | jq -r '.[] | select(.arg|test(\"minimize|kalk|nwg-drawer|rofi|Interrupt\")) | \"\(.modmask) \(.key) -> \(.arg)\"'"
run 'hyprctl getoption input:touchpad:disable_while_typing'

h "Leftovers from old .conf config / installer backups"
run "ls -la $C/hypr/"
run "find $C -maxdepth 4 \( -name '*.old' -o -name '*.old.*' -o -name '*.new' -o -name '*.bak*' -o -name '*.conf.save' \) -newermt '-30 days' 2>/dev/null"
run "ls -la ~/ii-original-dots-backup ~/ii-original-dots-backup/.config 2>/dev/null"
[ -n "$REPO" ] && run "ls -la '$REPO/.update-backups' '$REPO/.exp-merge-backups' 2>/dev/null"

h "Hyprbars / plugins"
run 'hyprpm list'
run "ls -la ~/.local/share/hyprpm ~/.cache/hyprpm 2>/dev/null"
LIMIT=80 run "grep -rIl -i 'hyprbars\|hyprpm\|plugin *{' $C/hypr ~/ii-original-dots-backup 2>/dev/null"
LIMIT=80 run "grep -rIn -i -A2 'hyprbars' $C/hypr/hyprland.conf.old $C/hypr/*.old* ~/ii-original-dots-backup/.config/hypr 2>/dev/null"

h "Traffic-light buttons (GTK / Electron / VS Code)"
for f in gtk-3.0/gtk.css gtk-4.0/gtk.css gtk-3.0/settings.ini gtk-4.0/settings.ini code-flags.conf electron-flags.conf chrome-flags.conf; do
    [ -e "$C/$f" ] && { echo "--- $C/$f ($(stat -c '%y' "$C/$f" | cut -d. -f1))"; head -40 "$C/$f"; }
done
LIMIT=40 run "grep -rIl -i 'traffic\|titlebutton\|window-controls\|\\.close\b\|\\.minimize\b\|\\.maximize\b' $C/gtk-3.0 $C/gtk-4.0 $C/matugen ~/ii-original-dots-backup 2>/dev/null"
run "gsettings get org.gnome.desktop.wm.preferences button-layout"
for s in "$C/Code/User/settings.json" "$C/Code - OSS/User/settings.json" "$C/VSCodium/User/settings.json"; do
    [ -f "$s" ] && { echo "--- $s"; grep -n -i 'titleBar\|window\.controls\|custom-css\|vscode_custom_css\|apc\.' "$s"; }
done

h "Live quickshell vs repo (live-only edits get wiped by installer rsync --delete)"
[ -n "$REPO" ] && LIMIT=80 run "diff -rq '$REPO/dots/.config/quickshell/ii' $C/quickshell/ii | grep -v '__pycache__'"

h "Quickshell crashes"
run "ls -lt ~/.cache/quickshell/crashes 2>/dev/null | head"
latest=$(ls -td ~/.cache/quickshell/crashes/*/ 2>/dev/null | head -1)
[ -n "$latest" ] && { echo "--- latest: $latest"; ls -la "$latest"; LIMIT=80 run "cat '$latest'/report.txt 2>/dev/null || cat '$latest'/info.txt"; }
run "coredumpctl list --no-pager 2>/dev/null | grep -i -E 'quickshell|qs ' | tail -8"
latestlog=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ 2>/dev/null | sed -n 2p)
[ -n "$latestlog" ] && LIMIT=40 run "qs log '$latestlog/log.qslog' 2>/dev/null | grep -E 'ERROR|FATAL|crash|abort|Segmentation' | tail -40"
run "journalctl --user -b --no-pager -g 'quickshell|qs\\[' -p warning | tail -20"

echo; echo "Report saved: $OUT"
