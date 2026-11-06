-- Autostart (ported from execs.conf)
-- Former exec-once commands go inside the hyprland.start handler

hl.on("hyprland.start", function ()
    -- Refresh pacman mirrorlist at login
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/refresh-mirrors.sh")

    -- Stop triggerhappy (it handles brightness keys for SDDM; avoid double triggers in Hyprland)
    hl.exec_cmd("sudo systemctl stop triggerhappy")

    -- Ferdium on Wayland
    -- hl.exec_cmd("ferdium --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime")

    -- Firewall applet
    -- hl.exec_cmd("firewall-applet")
end)
