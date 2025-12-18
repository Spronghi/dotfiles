-- Pull in the wezterm API
local wezterm = require("wezterm")
local sessionizer = require("sessionizer")

local act = wezterm.action

return function(config)
  config.keys = {}

  -- leader key
  config.leader = { key = " ", mods = "CTRL", timeout_milliseconds = 4000 }

  config.keys = {
    --------------- SPLIT PANES ---------------

    -- split pane horizontally
    {
      key = "v",
      mods = "LEADER",
      action = act.SplitHorizontal { domain = "CurrentPaneDomain" }
    },

    -- split pane vertically
    {
      key = "s",
      mods = "LEADER",
      action = act.SplitVertical { domain = "CurrentPaneDomain" }
    },

    -- split pane vertically but small
    {
      key = "a",
      mods = "LEADER",
      action = wezterm.action.SplitPane {
        direction = 'Right',
        command = { domain = 'CurrentPaneDomain' },
        size = { Percent = 20 },
      },
    },

    --------------- MANAGE PANES ---------------

    -- zoom current pane
    {
      key = "z",
      mods = "LEADER",
      action = act.TogglePaneZoomState,
    },

    -- move to panes
    {
      key = "k",
      mods = "LEADER",
      action = act.ActivatePaneDirection "Up",
    },

    {
      key = "j",
      mods = "LEADER",
      action = act.ActivatePaneDirection "Down",
    },

    {
      key = "h",
      mods = "LEADER",
      action = act.ActivatePaneDirection "Left",
    },

    {
      key = "l",
      mods = "LEADER",
      action = act.ActivatePaneDirection "Right",
    },

    -- close current pane
    {
      key = "w",
      mods = "LEADER",
      action = act.CloseCurrentPane { confirm = true },
    },

    -- rotate panes
    {
      key = "q",
      mods = "LEADER",
      action = act.RotatePanes "CounterClockwise",
    },

    -- show pane select mode
    {
      key = "p",
      mods = "CTRL",
      action = wezterm.action { PaneSelect = {} },
    },


    --------------- TABS ---------------

    -- activate copy mode
    {
      key = "x",
      mods = "CTRL",
      action = act.ActivateCopyMode
    },

    -- Open a new tab
    {
      key = "t",
      mods = "ALT",
      action = act.SpawnTab "CurrentPaneDomain",
    },

    -- Rename current tab
    {
      key = "r",
      mods = "LEADER",
      action = act.PromptInputLine {
        description = "Enter new name for tab",
        action = wezterm.action_callback(function(window, _, line)
          -- line will be `nil` if they hit escape without entering anything
          -- An empty string if they just hit enter
          -- Or the actual line of text they wrote
          if line then
            window:active_tab():set_title(line)
          end
        end),
      },
    },

    -- Enable debug
    { key = 'd', mods = 'LEADER', action = wezterm.action.ShowDebugOverlay },

    --------------- WORKSPACES/SESSIONS ---------------

    -- Show the launcher in selection mode to select a workspace
    {
      key = "e",
      mods = "CTRL",
      action = act.ShowLauncherArgs {
        flags = "WORKSPACES",
      },
    },


    -- Show the launcher in fuzzy selection mode to select a workspace
    {
      key = "/",
      mods = "CTRL",
      action = act.ShowLauncherArgs {
        flags = "FUZZY|WORKSPACES",
      },
    },

    -- Show the default launcher with all the options
    {
      key = "e",
      mods = "LEADER",
      action = act.ShowLauncher,
    },

    -- Prompt for a name to use for a new workspace and switch to it.
    {
      key = "t",
      mods = "LEADER",
      action = act.PromptInputLine {
        description = wezterm.format {
          { Attribute = { Intensity = "Bold" } },
          { Foreground = { AnsiColor = "Fuchsia" } },
          { Text = "Enter name for new workspace" },
        },
        action = wezterm.action_callback(function(window, pane, line)
          -- line will be `nil` if they hit escape without entering anything
          -- An empty string if they just hit enter
          -- Or the actual line of text they wrote
          if line then
            window:perform_action(
              act.SwitchToWorkspace {
                name = line,
              },
              pane
            )
          end
        end),
      },
    },

    -- Navigate to the next workspace
    {
      key = "[",
      mods = "CTRL",
      action = act.SwitchWorkspaceRelative(1)
    },

    -- Navigate to the previous workspace
    {
      key = "]",
      mods = "CTRL",
      action = act.SwitchWorkspaceRelative(-1)
    },

    -- Show CPU monitor
    {
      key = "u",
      mods = "LEADER",
      action = act.SwitchToWorkspace {
        name = "monitoring",
        spawn = {
          args = { "top" },
        },
      },
    },

    -- toggle full screen
    {
      key = 'n',
      mods = 'LEADER',
      action = wezterm.action.ToggleFullScreen,
    },

    -- sessionizer
    { key = "f", mods = "LEADER", action = wezterm.action_callback(sessionizer.toggle) },
  }

  for i = 1, 8 do
    -- ALT + number to move to that position
    table.insert(config.keys, {
      key = tostring(i),
      mods = "ALT",
      action = act.ActivateTab(i - 1),
    })
  end
end
