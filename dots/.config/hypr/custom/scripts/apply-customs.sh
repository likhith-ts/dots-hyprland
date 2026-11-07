#!/usr/bin/env bash
# Apply likhith-customs from the repo to the live config WITHOUT running the upstream installer.
# Safe to re-run. Backs up everything it touches to ~/customs-apply-backup-<timestamp>/.
#
# Usage (from anywhere):  ~/dotfiles/dots-hyprland/dots/.config/hypr/custom/scripts/apply-customs.sh
set -uo pipefail
REPO="$(cd "$(dirname "$0")/../../../../.." && pwd)"
C="$HOME/.config"
BK="$HOME/customs-apply-backup-$(date +%Y%m%d-%H%M%S)"
OLD="$HOME/ii-original-dots-backup/.config"
mkdir -p "$BK"
say() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
[ -d "$REPO/dots/.config/hypr/custom" ] || { echo "Can't find repo at $REPO"; exit 1; }
echo "Repo: $REPO  ($(git -C "$REPO" rev-parse --abbrev-ref HEAD) @ $(git -C "$REPO" rev-parse --short HEAD))"
echo "Backup dir: $BK"

say "1. Hyprland custom config (the installer skips this folder if it already exists)"
cp -a "$C/hypr/custom" "$BK/hypr-custom"
mkdir -p "$C/hypr/custom/legacy-conf"
for f in "$C"/hypr/custom/*.conf "$C"/hypr/custom/keybinds.conf.save; do
    [ -e "$f" ] && mv -v "$f" "$C/hypr/custom/legacy-conf/"   # Hyprland 0.57 no longer reads .conf; kept for reference
done
rsync -a --exclude 'plugins/*.so' --exclude 'plugins/.hyprbars-disabled' "$REPO/dots/.config/hypr/custom/" "$C/hypr/custom/"
chmod +x "$C"/hypr/custom/scripts/*.sh

say "2. GTK4 traffic lights (matugen template)"
T="$C/matugen/templates/gtk-4.0/gtk.css"
[ -f "$T" ] && cp -a "$T" "$BK/matugen-gtk4-gtk.css"
install -Dm644 "$REPO/dots/.config/matugen/templates/gtk-4.0/gtk.css" "$T"
if [ -d "$C/gtk-4.0/windows-assets" ]; then echo "windows-assets present ($(ls "$C/gtk-4.0/windows-assets" | wc -l) files)"
else echo "WARNING: $C/gtk-4.0/windows-assets is missing: the traffic-light PNGs come from the WhiteSur/MacTahoe theme installer (./install.sh -l / tweaks.sh)"; fi
SW="$C/quickshell/ii/scripts/colors/switchwall.sh"
[ -x "$SW" ] && { echo "Regenerating colors..."; "$SW" --noswitch >/dev/null 2>&1 && echo "done" || echo "switchwall failed; change wallpaper once to regenerate"; }

say "3. Electron flags overwritten by the installer"
for f in code-flags.conf chrome-flags.conf thorium-flags.conf; do
    [ -f "$OLD/$f" ] || continue
    if ! cmp -s "$OLD/$f" "$C/$f"; then
        echo "--- $f: yours (backup) vs installer's (current)"; diff "$OLD/$f" "$C/$f"
        cp -a "$C/$f" "$BK/$f.installer-version"
        cp -a "$OLD/$f" "$C/$f"; echo "restored your $f"
    else echo "$f unchanged"; fi
done

say "4. Reload Hyprland"
hyprctl reload >/dev/null; sleep 1
errs=$(hyprctl configerrors)
if [ -z "${errs//[$'\n ']/}" ]; then echo "No config errors"; else echo "CONFIG ERRORS:"; echo "$errs"; fi
echo "Custom binds loaded: $(hyprctl binds -j | jq '[.[] | select((.description // "")|startswith("Custom:"))] | length')"
echo "Super interrupt binds: $(hyprctl binds -j | jq '[.[] | select(((.key // "")|tostring|startswith("code:")) or ((.keycode // 0) > 0))] | length')"

say "5. Hyprbars"
if [ -f "$C/hypr/custom/plugins/hyprbars.so" ]; then hyprctl plugin list | grep -qi hyprbars && echo "hyprbars loaded" || echo "hyprbars.so present but not loaded: check hyprctl configerrors / notifications"
else echo "Not built yet for Hyprland $(hyprctl version -j | jq -r .tag). Run: $C/hypr/custom/scripts/build-hyprbars.sh"; fi

say "6. VS Code traffic lights"
echo "Your CSS files are intact in ~/.config/Code/User/ (macos-buttons.css, fontsBlend.css)."
echo "VS Code updates undo the Custom CSS injection: Ctrl+Shift+P -> 'Enable Custom CSS and JS' -> restart VS Code."

echo; echo "Done. Backup of everything replaced: $BK"
