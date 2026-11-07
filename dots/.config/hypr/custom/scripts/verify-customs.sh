#!/usr/bin/env bash
# Smoke test for likhith-customs after an upstream sync. Run inside a Hyprland session.
pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }
chk() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

echo "== Config load"
hyprctl reload >/dev/null 2>&1; sleep 1
errs=$(hyprctl configerrors 2>/dev/null | grep -v '^$')
[ -z "$errs" ] && ok "no Hyprland config errors" || { bad "config errors:"; echo "$errs" | sed 's/^/        /'; }

echo "== Settings"
chk "touchpad disable_while_typing = false" \
    "hyprctl getoption input:touchpad:disable_while_typing -j | jq -e '.int == 0'"

echo "== Keybinds registered (Lua binds show a numeric arg, so match on description)"
for k in "Minimize window" "Toggle minimized view" "Restore all minimized" "Toggle hyprbars" "Apps grid" "Jarvis search" "Toggle left sidebar" "Toggle smart split"; do
    chk "bind: $k" "hyprctl binds -j | jq -e --arg k '$k' 'any(.[]; (.description // \"\") | contains(\$k))'"
done
chk "Super interrupt binds present" "hyprctl binds -j | jq -e '[.[] | select(((.key // \"\")|tostring|startswith(\"code:\")) or ((.keycode // 0) > 0))] | length > 100'"
chk "no stale upstream Super+B/Super+S binds" "[ \$(hyprctl binds -j | jq '[.[] | select(.modmask==64 and (.key==\"B\" or .key==\"b\" or .key==\"S\" or .key==\"s\"))] | length') -le 2 ]"

echo "== Environment"
chk "XDG_DATA_DIRS has flatpak"  "tr '\0' '\n' < /proc/\$(pgrep -x Hyprland | head -1)/environ | grep '^XDG_DATA_DIRS=' | grep -q flatpak"
chk "XDG_DATA_DIRS has snapd"    "tr '\0' '\n' < /proc/\$(pgrep -x Hyprland | head -1)/environ | grep '^XDG_DATA_DIRS=' | grep -q snapd"

echo "== Quickshell"
chk "quickshell alive"           "qs -c ii ipc call TEST_ALIVE"
chk "minimize IPC target exists" "qs -c ii ipc show | grep -q 'target minimize'"

echo "== Dispatch syntax (live)"
chk "hl.dsp dispatch works"      "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"minimize\")' && hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"minimize\")'"

echo
echo "Result: $pass passed, $fail failed"
echo "Manual: Super+H (genie into dock), Super+Shift+H (overlay), click minimized app in dock (restores), Ctrl+Super+C (Kalk top-right)."
exit $fail
