-- Custom window/layer rules (ported from live rules.conf)
-- See ~/.config/hypr/hyprland/rules.lua for examples
-- Hyprbars rules live in custom/hyprbars.lua

-- Smart gaps (no gaps with one tiled window, ignoring special workspaces)
-- hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })

-- Tearing (immediate) for floating windows
hl.window_rule({ match = { float = true }, immediate = true })

-- illogical-impulse Settings: pinned on all workspaces, dim the rest
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, pin = true })
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, dim_around = true })
-- stay_focused here makes the snipping tool glitch on the settings layer, left off.

-- VS Code unsaved-file prompt
-- hl.window_rule({ match = { class = "^(code)$", float = true }, stay_focused = true })
-- hl.window_rule({ match = { class = "^(code)$", float = true }, dim_around = true })

-- MEGAsync
hl.window_rule({ match = { class = "^(nz.co.mega.megasync)$" }, float = true })

-- Taildrop device list
local taildrop = { title = ".*taildrop.*" }
hl.window_rule({ match = taildrop, float = true })
hl.window_rule({ match = taildrop, center = true })
hl.window_rule({ match = taildrop, size = {"(monitor_w*0.70)", "(monitor_h*0.50)"} })

-- hyprshell overlay
hl.layer_rule({ match = { namespace = "^(hyprshell)$" }, blur = true })
hl.layer_rule({ match = { namespace = "^(hyprshell)$" }, ignore_alpha = 0.5 })

-- Kalk (KDE calculator) as a top-right scratchpad (launched by custom/scripts/kalk-toggle.sh)
local kalk = { class = "^(org.kde.kalk)$" }
hl.window_rule({ match = kalk, workspace = "special:kalk silent" })
hl.window_rule({ match = kalk, float = true })
hl.window_rule({ match = kalk, size = {400, 550} })
hl.window_rule({ match = kalk, max_size = {400, 650} })
hl.window_rule({ match = kalk, move = {1519, 1} })
hl.window_rule({ match = kalk, keep_aspect_ratio = true })
hl.window_rule({ match = kalk, animation = "slide right" })
-- hl.window_rule({ match = kalk, pin = true })
