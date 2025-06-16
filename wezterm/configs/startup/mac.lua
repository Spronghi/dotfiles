local wezterm = require("wezterm")
local utils = require("utils")

local mux = wezterm.mux


local function start_random(args)
  local scripts_dir = wezterm.home_dir
  local _, _, _ = mux.spawn_window {
    workspace = "random",
    cwd = scripts_dir,
    args = args,
  }
end

return function(config)
  if utils.is_windows() or utils.is_linux() then
    return
  end

  wezterm.on("gui-startup", function(cmd)
    local args = {}
    if cmd then
      args = cmd.args
    end

    start_random(args)

    mux.set_active_workspace "random"
  end)
end
