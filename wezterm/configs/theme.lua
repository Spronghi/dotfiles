local utils = require("utils")
local configs = require("configs")
local wezterm = require("wezterm")

return function(config)
  -- show session name on the right of the tab
  wezterm.on("update-status", function(window, _)
    window:set_left_status(window:active_workspace() .. " | ")
  end)

  config.use_fancy_tab_bar = false
  config.show_new_tab_button_in_tab_bar = false
  config.tab_bar_at_bottom = true

  -- hide the window top bar
  config.window_decorations = "RESIZE"

  config.window_padding = {
    -- top = 0,
    bottom = 0,
    -- left = 0,
    -- right = 0,
  }

  config.inactive_pane_hsb = {
    brightness = 0.6,
  }

  if configs.color_scheme == "ayu" then
    config.color_scheme = "Ayu Dark (Gogh)"
  elseif configs.color_scheme == "tokyo" then
    config.color_scheme = "Tokyo Night Moon"
  else
    -- default color scheme is "rose-pine"
    config.color_scheme = configs.color_scheme or "rose-pine"
  end

  if utils.is_windows() then
    config.font_size = 11
  else
    config.font_size = 15
  end

  config.colors = {
    background = "black",
    -- Make the selection text color fully transparent.
    -- When fully transparent, the current text color will be used.
    selection_fg = "none",
    -- Set the selection background color with alpha.
    -- When selection_bg is transparent, it will be alpha blended over
    -- the current cell background color, rather than replace it
    selection_bg = "rgba(50% 50% 50% 50%)",
    tab_bar = {
      background = "transparent",
      active_tab = {
        bg_color = "transparent",
        fg_color = "#f6c177",
      },
      inactive_tab = {
        bg_color = "transparent",
        fg_color = "#6e6a86",
      },
      inactive_tab_hover = {
        bg_color = "transparent",
        fg_color = "#e0def4",
      },
    },
  }

  config.text_background_opacity = 0.9

  if utils.is_windows() then
    config.window_background_opacity = 0.95
  else
    config.window_background_opacity = 0.80
  end
end
