-- Workspace MRU history, the CTRL+] toggle, and a CMD+W that survives
-- killing a workspace.
--
-- A simple current/previous pair breaks when a workspace dies (closing
-- its last tab destroys it), so we keep a most-recent-first history and
-- toggle to the first entry still alive. Stored in wezterm.GLOBAL
-- because module locals are wiped on every config reload; kept as a
-- delimited string because nested tables in wezterm.GLOBAL don't behave
-- like plain Lua tables.

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local SEP = "\x1f"
local MAX_HISTORY = 10

local function history()
  local hist = {}
  for name in (wezterm.GLOBAL.workspace_history or ""):gmatch("[^" .. SEP .. "]+") do
    table.insert(hist, name)
  end
  return hist
end

local function save(hist)
  wezterm.GLOBAL.workspace_history = table.concat(hist, SEP)
end

local function alive_set()
  local set = {}
  for _, name in ipairs(wezterm.mux.get_workspace_names()) do
    set[name] = true
  end
  return set
end

-- Most recent live workspace other than `current`; prunes dead entries
-- and falls back to any live workspace so callers never dead-end on a
-- history full of dead names.
M.previous = function(current)
  local alive = alive_set()
  local pruned, target = {}, nil
  for _, name in ipairs(history()) do
    if alive[name] then
      table.insert(pruned, name)
      if not target and name ~= current then target = name end
    end
  end
  save(pruned)

  if not target then
    for name in pairs(alive) do
      if name ~= current then
        target = name
        break
      end
    end
  end
  return target
end

wezterm.on("update-status", function(window, _)
  local active = window:active_workspace()
  local current = wezterm.GLOBAL.current_workspace
  if current == active then return end
  wezterm.GLOBAL.current_workspace = active
  if current == nil then return end

  -- Push the workspace we came from onto the history front. It may
  -- already be dead; M.previous prunes dead entries when reading.
  local hist = { current }
  for _, name in ipairs(history()) do
    if name ~= current and name ~= active and #hist < MAX_HISTORY then
      table.insert(hist, name)
    end
  end
  save(hist)
end)

-- Toggle to the last active workspace.
M.toggle_last = wezterm.action_callback(function(window, pane)
  local target = M.previous(window:active_workspace())
  if target then
    window:perform_action(act.SwitchToWorkspace({ name = target }), pane)
  else
    wezterm.log_info("workspaces: no other live workspace to toggle to")
  end
end)

-- Close the current tab. Closing the last tab of a workspace destroys
-- the workspace and wezterm can leave the window stuck on the dead one,
-- so in that case switch to the previous workspace first, then kill the
-- old tab's panes in the background.
M.close_tab = wezterm.action_callback(function(window, pane)
  if #window:mux_window():tabs() > 1 then
    window:perform_action(act.CloseCurrentTab({ confirm = true }), pane)
    return
  end

  local target = M.previous(window:active_workspace())
  if not target then
    -- nowhere to land anyway; let wezterm close the window
    window:perform_action(act.CloseCurrentTab({ confirm = true }), pane)
    return
  end

  local doomed = window:active_tab()
  window:perform_action(act.SwitchToWorkspace({ name = target }), pane)

  local cli = wezterm.executable_dir .. "/wezterm"
  for _, p in ipairs(doomed:panes()) do
    wezterm.run_child_process({ cli, "cli", "kill-pane", "--pane-id", tostring(p:pane_id()) })
  end
end)

return M
