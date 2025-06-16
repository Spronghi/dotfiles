local wezterm = require("wezterm")
local utils = require("utils")

local mux = wezterm.mux

local wsl_home = "/home/spronghi"

local function start_dotfiles(args)
  local dir = wezterm.home_dir .. "/dotfiles"
  local _, pane, _ = mux.spawn_window {
    workspace = "dotfiles",
    cwd = dir,
    args = args,
  }
  pane:send_text "nvim .\n"
end

local function start_luckytopdeck(args)
  local dir = wsl_home .. "/workspace/lucky-topdeck"

  local _, pane, window = mux.spawn_window {
    workspace = "lucky-topdeck",
    cwd = dir,
    args = args,
  }
  pane:send_text "nvim .\n"

  local _, console_pane, _ = window:spawn_tab {
    cwd = dir,
    args = args,
  }
  console_pane:send_text("cd " .. dir .. "\nnpm run dev\n")
end

return function(config)
  if not utils.is_windows() then
    return
  end

  wezterm.on("gui-startup", function(cmd)
    local args = {}
    if cmd then
      args = cmd.args
    end

    start_dotfiles(args)
    start_luckytopdeck(args)

    mux.set_active_workspace "dotfiles"
  end)
end
