-- Pull in the wezterm API
local wezterm = require("wezterm")
local sessionizer = require("sessionizer")

local act = wezterm.action

local workspace_root = wezterm.home_dir .. "/workspace"

local function workspace_exists(name)
  for _, n in ipairs(wezterm.mux.get_workspace_names()) do
    if n == name then return true end
  end
  return false
end

-- Workspace MRU history for the CTRL+] toggle.
--
-- A simple current/previous pair breaks when a workspace dies (closing its
-- last tab destroys it and wezterm silently switches away), so we keep a
-- most-recent-first history instead and toggle to the first entry that is
-- still alive. Stored in wezterm.GLOBAL because module locals are wiped on
-- every config reload; kept as a delimited string because nested tables in
-- wezterm.GLOBAL don't behave like plain Lua tables.
local SEP = "\x1f"

local function history_list()
  local hist = {}
  for name in (wezterm.GLOBAL.workspace_history or ""):gmatch("[^" .. SEP .. "]+") do
    table.insert(hist, name)
  end
  return hist
end

local function history_save(hist)
  wezterm.GLOBAL.workspace_history = table.concat(hist, SEP)
end

wezterm.on("update-status", function(window, _)
  local active = window:active_workspace()
  local current = wezterm.GLOBAL.current_workspace
  if current == active then return end
  wezterm.GLOBAL.current_workspace = active
  if current == nil then return end

  -- Push the workspace we came from onto the history front. It may already
  -- be dead (last tab closed); the toggle prunes dead entries when reading.
  local hist = { current }
  for _, name in ipairs(history_list()) do
    if name ~= current and name ~= active and #hist < 10 then
      table.insert(hist, name)
    end
  end
  history_save(hist)
end)

local function switch_to_last_workspace(window, pane)
  local active = window:active_workspace()
  local alive, target = {}, nil
  for _, name in ipairs(history_list()) do
    if workspace_exists(name) then
      table.insert(alive, name)
      if target == nil and name ~= active then target = name end
    end
  end
  history_save(alive)

  if target then
    window:perform_action(act.SwitchToWorkspace { name = target }, pane)
  else
    wezterm.log_info("toggle: no other live workspace in history")
  end
end

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
      action = wezterm.action.SplitPane {
        direction = 'Right',
        command = { domain = 'CurrentPaneDomain' },
        size = { Percent = 50 },
      },
    },

    -- split pane down
    {
      key = "s",
      mods = "LEADER",
      action = wezterm.action.SplitPane {
        direction = 'Down',
        command = { domain = 'CurrentPaneDomain' },
        size = { Percent = 50 },
      },
    },

    -- split pane up
    {
      key = "S",
      mods = "LEADER",
      action = wezterm.action.SplitPane {
        direction = 'Up',
        command = { domain = 'CurrentPaneDomain' },
        size = { Percent = 50 },
      },
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
      mods = "ALT",
      action = act.CloseCurrentPane { confirm = true },
    },

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

    -- -- Navigate to the next workspace
    -- {
    --   key = "[",
    --   mods = "CTRL",
    --   action = act.SwitchWorkspaceRelative(1)
    -- },

    -- Toggle to the last active workspace
    {
      key = "]",
      mods = "CTRL",
      action = wezterm.action_callback(switch_to_last_workspace)
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
    {
      key = "f",
      mods = "LEADER",
      action = sessionizer.show({
        options = { title = "workspaces", prompt = "> " },
        processing = sessionizer.GroupedLabels { root = workspace_root },
        sessionizer.NewWorkspace {},
        sessionizer.FdSearch(workspace_root),
      }),
    },
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
