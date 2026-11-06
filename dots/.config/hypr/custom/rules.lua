-- Custom window/layer/workspace rules (ported from rules.conf)
-- See ~/.config/hypr/hyprland/rules.lua for examples

-- Kalk (KDE calculator) as a top-right scratchpad
local kalk = { class = "^(org.kde.kalk)$" }
hl.window_rule({ match = kalk, workspace = "special:kalk silent" })
hl.window_rule({ match = kalk, float = true })
hl.window_rule({ match = kalk, size = {400, 550} })
hl.window_rule({ match = kalk, max_size = {400, 650} })
hl.window_rule({ match = kalk, move = {1519, 1} })
hl.window_rule({ match = kalk, keep_aspect_ratio = true })
hl.window_rule({ match = kalk, animation = "slide right" })
-- hl.window_rule({ match = kalk, pin = true })

-- VS Code unsaved-file prompt
-- hl.window_rule({ match = { class = "^(code)$", float = true }, stay_focused = true })
-- hl.window_rule({ match = { class = "^(code)$", float = true }, dim_around = true })
