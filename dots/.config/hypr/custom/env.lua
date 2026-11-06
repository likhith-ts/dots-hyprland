-- Extra environment variables (ported from env.conf)
-- See ~/.config/hypr/hyprland/env.lua for examples

local home_dir = os.getenv("HOME")

-- Snap support.
-- Rebuilds upstream's XDG_DATA_DIRS (flatpak + system) and appends snap, because
-- os.getenv() returns the pre-Hyprland value, not what hyprland/env.lua just set.
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
hl.env("XDG_DATA_DIRS", home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs_old .. ":/var/lib/snapd/desktop")
hl.env("PATH", (os.getenv("PATH") or "") .. ":/snap/bin")
