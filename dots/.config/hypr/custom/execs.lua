-- Autostart (ported from live execs.conf)

hl.on("hyprland.start", function ()
    -- Refresh pacman mirrorlist at login
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/refresh-mirrors.sh")

    -- triggerhappy handles brightness keys for SDDM; stop it to avoid double triggers in Hyprland
    hl.exec_cmd("sudo systemctl stop triggerhappy")

    -- hyprshell (Alt+Tab window switcher across workspaces)
    hl.exec_cmd("hyprshell run")

    -- Hyprbars is loaded by custom/hyprbars.lua (no exec needed)

    -- hl.exec_cmd("ferdium --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime")
    -- hl.exec_cmd("firewall-applet")
end)
