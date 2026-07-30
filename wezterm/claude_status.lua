-- Claude Code session tracking for wezterm:
--   * renders open sessions in the right status of the tab bar
--     (one entry per workspace, worst status wins);
--   * M.pick — fzf modal listing sessions; picking one jumps to the
--     pane running claude (bind it to a key).
--
-- State files are written by claude/claude-status-hook.sh as
-- "<workspace>\t<status>\t<ts>". A presence scan over mux panes covers
-- sessions the hooks can't see (started before the hooks existed);
-- those render as idle.
--
-- "completed" acts as an unread marker: it flips to "idle" (rewriting
-- the state file) once the user switches to the tab its pane lives in.

local wezterm = require("wezterm")
local sessionizer = require("sessionizer")
local act = wezterm.action

local M = {}

local DIR = "/tmp/claude-wezterm-status"
local STALE_SECONDS = 12 * 60 * 60

local STATUSES = {
  blocked   = { severity = 4, icon = "◆", color = "#eb6f92" }, -- rose-pine love
  running   = { severity = 3, icon = "●", color = "#f6c177" }, -- rose-pine gold
  completed = { severity = 2, icon = "✓", color = "#a6e3a1" }, -- green: done, all good
  idle      = { severity = 1, icon = "○", color = "#6e6a86" }, -- rose-pine muted
}

-- Whether the tab holding this pane is its window's active tab. A
-- workspace-level check alone would mark sessions "seen" the moment
-- the window gains focus, even when claude finished in a background
-- tab the user never looked at. Legacy files without a pane id, and
-- panes that died before the state file was cleaned up, fall back to
-- true (workspace match is then the only signal we have).
local function tab_is_active(pane_id)
  if not pane_id then return true end
  local ok, pane = pcall(wezterm.mux.get_pane, tonumber(pane_id))
  if not ok or not pane then return true end
  local tab = pane:tab()
  if not tab then return true end
  local win = tab:window()
  if not win then return true end
  local okt, active = pcall(function() return win:active_tab() end)
  if not okt or not active then return true end
  return active:tab_id() == tab:tab_id()
end

-- Statuses from the hook state files:
--   pane      — per-pane status (files that record a pane id);
--   workspace — per-workspace aggregate, worst status wins;
--   legacy    — per-workspace aggregate of files WITHOUT a pane id
--               (written by an older hook), used as a pane fallback.
local function read_statuses(active_workspace)
  local empty = { pane = {}, workspace = {}, legacy = {} }
  local ok, files = pcall(wezterm.read_dir, DIR)
  if not ok then return empty end

  local now = os.time()
  local result = empty

  local function keep_worst(map, key, status)
    local current = map[key]
    if not current or STATUSES[status].severity > STATUSES[current].severity then
      map[key] = status
    end
  end

  for _, path in ipairs(files) do
    local f = io.open(path, "r")
    if f then
      local line = f:read("l") or ""
      f:close()
      local workspace, status, ts, pane =
        line:match("^([^\t]+)\t([^\t]+)\t(%d+)\t(%d+)$")
      if not workspace then
        workspace, status, ts = line:match("^([^\t]+)\t([^\t]+)\t(%d+)$")
      end
      ts = tonumber(ts)

      if not (workspace and STATUSES[status] and ts) or now - ts > STALE_SECONDS then
        os.remove(path)
      else
        -- Seen: the user is looking at this workspace AND the tab the
        -- claude pane lives in; clear the unread mark and the matching
        -- macOS notification (state file name is the claude session id,
        -- same id the hook used for -group).
        if status == "completed" and workspace == active_workspace
            and tab_is_active(pane) then
          status = "idle"
          local w = io.open(path, "w")
          if w then
            w:write(workspace .. "\t" .. status .. "\t" .. ts
              .. (pane and ("\t" .. pane) or "") .. "\n")
            w:close()
          end
          pcall(wezterm.background_child_process, {
            "/opt/homebrew/bin/terminal-notifier",
            "-remove", "claude-" .. path:match("[^/]+$"),
          })
        end

        if pane then
          result.pane[tonumber(pane)] = status
        else
          keep_worst(result.legacy, workspace, status)
        end
        keep_worst(result.workspace, workspace, status)
      end
    end
  end

  return result
end

-- Panes with a live claude process in the foreground, per workspace.
local function claude_panes()
  local found = {}
  for _, mux_window in ipairs(wezterm.mux.all_windows()) do
    local workspace = mux_window:get_workspace()
    for _, tab in ipairs(mux_window:tabs()) do
      for _, pane in ipairs(tab:panes()) do
        local ok, info = pcall(pane.get_foreground_process_info, pane)
        if ok and info then
          local name = (info.name or ""):match("[^/]+$")
          local arg0 = ((info.argv or {})[1] or ""):match("[^/]+$")
          if name == "claude" or arg0 == "claude" then
            found[workspace] = found[workspace] or {}
            table.insert(found[workspace], pane)
          end
        end
      end
    end
  end
  return found
end

-- All known claude sessions: { workspace, status, pane_id? }.
-- pane_id is nil when a state file exists but no claude pane is
-- visible (navigation falls back to a workspace switch).
M.sessions = function(active_workspace)
  local statuses = read_statuses(active_workspace)
  local panes = claude_panes()
  local list, covered = {}, {}

  for workspace, plist in pairs(panes) do
    covered[workspace] = true
    for _, pane in ipairs(plist) do
      -- claude sets the pane title to the task summary, prefixed with
      -- a spinner glyph; keep the text from the first word onwards
      local title = (pane:get_title() or ""):match("[%w].*$") or ""
      local pane_id = pane:pane_id()
      table.insert(list, {
        workspace = workspace,
        pane_id = pane_id,
        -- per-pane when the hook recorded the pane; legacy files
        -- (no pane id) fall back to their workspace aggregate
        status = statuses.pane[pane_id] or statuses.legacy[workspace] or "idle",
        title = title,
      })
    end
  end

  for workspace, status in pairs(statuses.workspace) do
    if not covered[workspace] then
      table.insert(list, { workspace = workspace, status = status })
    end
  end

  return list
end

--------------- tab bar ---------------

wezterm.on("update-status", function(window, _)
  -- "Seen" (clears the unread ✓ and its notification) requires the
  -- window to be OS-focused: with wezterm in the background the active
  -- workspace is still whatever was left open, and flipping there
  -- would kill the notification an instant after the hook posts it.
  local seen_workspace = nil
  local ok, focused = pcall(function() return window:is_focused() end)
  if ok and focused then seen_workspace = window:active_workspace() end

  local by_workspace = {}
  for _, s in ipairs(M.sessions(seen_workspace)) do
    local current = by_workspace[s.workspace]
    if not current or STATUSES[s.status].severity > STATUSES[current].severity then
      by_workspace[s.workspace] = s.status
    end
  end

  local names = {}
  for workspace in pairs(by_workspace) do
    table.insert(names, workspace)
  end
  table.sort(names)

  local segments = {}
  for _, workspace in ipairs(names) do
    local s = STATUSES[by_workspace[workspace]]
    table.insert(segments, { Foreground = { Color = s.color } })
    table.insert(segments, { Text = workspace .. " " .. s.icon .. "  " })
  end

  window:set_right_status(wezterm.format(segments))
end)

--------------- picker ---------------

-- Selecting an entry jumps to the claude pane; if the pane died between
-- render and pick (or was never visible) fall back to the workspace.
local function navigate(window, pane, id)
  if not id then return end

  local pane_id, workspace = id:match("^pane:(%d+):(.+)$")
  if not pane_id then
    workspace = id:match("^ws:(.+)$")
  end
  if not workspace then return end

  if pane_id then
    local ok, target = pcall(wezterm.mux.get_pane, tonumber(pane_id))
    if ok and target then
      -- Focus restores clobber early activation twice: when the async
      -- SwitchToWorkspace lands, and again when the dying modal window
      -- (it lingers ~200ms) hands OS focus back to the origin window.
      -- So wait until the origin window is focused on the target
      -- workspace, THEN focus the claude pane.
      window:perform_action(act.SwitchToWorkspace({ name = workspace }), pane)
      local function focus_target(attempts)
        wezterm.time.call_after(0.05, function()
          local settled = pcall(function() return window:is_focused() end)
            and window:is_focused()
            and wezterm.mux.get_active_workspace() == workspace
          if not settled then
            if attempts > 0 then focus_target(attempts - 1) end
            return
          end
          local okp, p = pcall(wezterm.mux.get_pane, tonumber(pane_id))
          if okp and p then
            local tab = p:tab()
            if tab then
              -- another pane zoomed in this tab would keep covering
              -- the claude pane even once it holds the focus
              pcall(function() tab:set_zoomed(false) end)
              tab:activate()
            end
            p:activate()
          end
        end)
      end
      focus_target(40)
      return
    end
  end

  window:perform_action(act.SwitchToWorkspace({ name = workspace }), pane)
end

-- Action for a keybinding: fzf modal over M.sessions(), urgency first.
-- opts.on_tab (function(window, pane)) toggles to an alternate picker
-- when Tab is pressed in the modal.
M.pick = function(opts)
  opts = opts or {}
  return wezterm.action_callback(function(window, pane)
  local sessions = M.sessions(window:active_workspace())
  if #sessions == 0 then
    window:toast_notification("claude", "no claude sessions open", nil, 3000)
    return
  end

  table.sort(sessions, function(a, b)
    local sa, sb = STATUSES[a.status].severity, STATUSES[b.status].severity
    if sa ~= sb then return sa > sb end
    return a.workspace < b.workspace
  end)

  local schema = {
    options = {
      prompt = "claude > ",
      fzf_args = "--no-input --info=hidden --bind='j:down,k:up'",
      background = "black",
      callback = navigate,
      on_tab = opts.on_tab,
    },
  }
  local max_workspace = 0
  for _, s in ipairs(sessions) do
    if #s.workspace > max_workspace then max_workspace = #s.workspace end
  end

  for _, s in ipairs(sessions) do
    local meta = STATUSES[s.status]
    local segments = {
      { Foreground = { Color = meta.color } },
      {
        Text = s.workspace
          .. string.rep(" ", max_workspace - #s.workspace)
          .. "  " .. meta.icon .. " " .. s.status
          .. string.rep(" ", #"completed" - #s.status),
      },
    }
    if s.title and s.title ~= "" then
      table.insert(segments, { Foreground = { Color = "#908caa" } }) -- rose-pine subtle
      table.insert(segments, { Text = "  " .. s.title })
    end
    table.insert(schema, {
      label = wezterm.format(segments),
      id = s.pane_id and ("pane:" .. s.pane_id .. ":" .. s.workspace)
        or ("ws:" .. s.workspace),
    })
  end

  window:perform_action(sessionizer.show_fzf(schema), pane)
  end)
end

return M
