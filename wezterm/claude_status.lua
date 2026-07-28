-- Renders open Claude Code sessions in the right status of the tab bar:
-- one entry per workspace, worst status wins. State files are written
-- by claude/claude-status-hook.sh as "<workspace>\t<status>\t<ts>".
--
-- "completed" acts as an unread marker: it flips to "idle" (rewriting
-- the state file) once the user switches to that workspace.

local wezterm = require("wezterm")

local DIR = "/tmp/claude-wezterm-status"
local STALE_SECONDS = 12 * 60 * 60

local STATUSES = {
  blocked   = { severity = 4, icon = "◆", color = "#eb6f92" }, -- rose-pine love
  running   = { severity = 3, icon = "●", color = "#f6c177" }, -- rose-pine gold
  completed = { severity = 2, icon = "✓", color = "#a6e3a1" }, -- green: done, all good
  idle      = { severity = 1, icon = "○", color = "#6e6a86" }, -- rose-pine muted
}

local function read_sessions(active_workspace)
  local ok, files = pcall(wezterm.read_dir, DIR)
  if not ok then return {} end

  local now = os.time()
  local by_workspace = {}

  for _, path in ipairs(files) do
    local f = io.open(path, "r")
    if f then
      local line = f:read("l") or ""
      f:close()
      local workspace, status, ts = line:match("^([^\t]+)\t([^\t]+)\t(%d+)$")
      ts = tonumber(ts)

      if not (workspace and STATUSES[status] and ts) or now - ts > STALE_SECONDS then
        os.remove(path)
      else
        -- Seen: the user is looking at this workspace, clear the unread mark.
        if status == "completed" and workspace == active_workspace then
          status = "idle"
          local w = io.open(path, "w")
          if w then
            w:write(workspace .. "\t" .. status .. "\t" .. ts .. "\n")
            w:close()
          end
        end

        local current = by_workspace[workspace]
        if not current or STATUSES[status].severity > STATUSES[current].severity then
          by_workspace[workspace] = status
        end
      end
    end
  end

  return by_workspace
end

-- Workspaces with a live claude process in the foreground of some pane.
-- Covers sessions the hooks can't see (started before the hooks were
-- configured); without a state file they render as idle.
local function claude_workspaces()
  local found = {}
  for _, mux_window in ipairs(wezterm.mux.all_windows()) do
    local workspace = mux_window:get_workspace()
    if not found[workspace] then
      for _, tab in ipairs(mux_window:tabs()) do
        for _, pane in ipairs(tab:panes()) do
          local ok, info = pcall(pane.get_foreground_process_info, pane)
          if ok and info then
            local name = (info.name or ""):match("[^/]+$")
            local arg0 = ((info.argv or {})[1] or ""):match("[^/]+$")
            if name == "claude" or arg0 == "claude" then
              found[workspace] = true
              break
            end
          end
        end
        if found[workspace] then break end
      end
    end
  end
  return found
end

wezterm.on("update-status", function(window, _)
  local sessions = read_sessions(window:active_workspace())

  for workspace in pairs(claude_workspaces()) do
    if not sessions[workspace] then
      sessions[workspace] = "idle"
    end
  end

  local names = {}
  for workspace in pairs(sessions) do
    table.insert(names, workspace)
  end
  table.sort(names)

  local segments = {}
  for _, workspace in ipairs(names) do
    local s = STATUSES[sessions[workspace]]
    table.insert(segments, { Foreground = { Color = s.color } })
    table.insert(segments, { Text = workspace .. " " .. s.icon .. "  " })
  end

  window:set_right_status(wezterm.format(segments))
end)
