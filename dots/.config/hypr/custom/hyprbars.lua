-- Hyprbars: macOS-style traffic-light title bars (ported from live general.conf + rules.conf)
--
-- Plugin binary: ~/.config/hypr/custom/plugins/hyprbars.so
--   Build/rebuild it for your current Hyprland with: custom/scripts/build-hyprbars.sh
--   (the old /var/cache/hyprpm build was compiled for an older Hyprland and won't load on 0.57)
-- Toggle at runtime: Super+B (custom/scripts/toggle_hyprbars.sh)

local HOME_DIR      = os.getenv("HOME")
local HYPRBARS_SO   = HOME_DIR .. "/.config/hypr/custom/plugins/hyprbars.so"
local DISABLED_FLAG = HOME_DIR .. "/.config/hypr/custom/plugins/.hyprbars-disabled"
local SCRIPTS       = HOME_DIR .. "/.config/hypr/custom/scripts"

local function exists(p) local f = io.open(p, "r"); if f then f:close(); return true end; return false end

if not exists(HYPRBARS_SO) or exists(DISABLED_FLAG) then
    return
end

hl.plugin.load(HYPRBARS_SO)

-- Plugin options/rules only exist after the plugin has registered them.
-- On the first parse after login they may not exist yet, so reload once on start.
if not (hl.plugin.hyprbars and hl.plugin.hyprbars.add_button) then
    hl.on("hyprland.start", function()
        hl.exec_cmd("sleep 1 && hyprctl reload")
    end)
    return
end

hl.config({
    plugin = {
        hyprbars = {
            -- bar_blur = true,
            -- bar_color = "rgba(38,38,38,0.8)",
            bar_text_font = "SF Pro Display",
            bar_buttons_alignment = "left",
            icon_on_hover = true,
            bar_part_of_window = true,
            inactive_button_color = "rgb(70,73,79)",
        },
    },
})

-- Buttons (same order as before: close, minimize, maximize)
hl.plugin.hyprbars.add_button({ bg_color = "rgb(ff5f57)", fg_color = "rgba(0,0,0,0.55)", size = 15, icon = "󰖭",
    action = "hl.dsp.window.close()" })
hl.plugin.hyprbars.add_button({ bg_color = "rgb(febc2e)", fg_color = "rgba(0,0,0,0.55)", size = 15, icon = "─",
    action = 'hl.dsp.exec_cmd("' .. SCRIPTS .. '/minimize.sh minimize")' })
hl.plugin.hyprbars.add_button({ bg_color = "rgb(28c940)", fg_color = "rgba(0,0,0,0.55)", size = 15, icon = "⤢",
    action = 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })' })

-- No bar for apps that draw their own traffic lights
hl.window_rule({ match = { class = "^(code|google-chrome|localsend|org.gnome.tweaks|org.gnome.Evince)$" },
    ["hyprbars:no_bar"] = true })
-- Translucent bar for kitty
hl.window_rule({ match = { class = "^(kitty)$" }, ["hyprbars:bar_color"] = "rgba(38,38,38,0.8)" })
