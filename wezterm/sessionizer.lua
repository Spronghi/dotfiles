-- Sessionizer modeled after mikkasendke/sessionizer.wezterm:
-- a schema of entries/generators is evaluated on show(), run through
-- processing functions, then rendered with an InputSelector.
--
-- Schema shape:
--   {
--     options = { title, prompt, always_fuzzy, callback },
--     processing = fn | { fn, ... },   -- each fn mutates the entries list
--     <entries>,                       -- string | {label,id} | generator fn | nested schema
--   }

local wezterm = require("wezterm")
local act = wezterm.action

local sessionizer = {}

--------------- helpers ---------------

local function append_each(source, destination)
  for _, value in ipairs(source) do
    table.insert(destination, value)
  end
end

local function merge_tables(t1, t2)
  if not t2 then return end
  for k, v in pairs(t2) do
    if type(v) == "table" and type(t1[k]) == "table" then
      merge_tables(t1[k], v)
    else
      t1[k] = v
    end
  end
end

sessionizer.for_each_entry = function(f)
  return function(entries)
    for _, entry in ipairs(entries) do
      f(entry)
    end
  end
end

--------------- default callback ---------------

local NEW_WORKSPACE_ID = "__new__"

sessionizer.DefaultCallback = function(window, pane, id, _)
  if not id then return end

  if id == NEW_WORKSPACE_ID then
    window:perform_action(
      act.PromptInputLine({
        description = "workspace name",
        action = wezterm.action_callback(function(w, p, name)
          if name and name ~= "" then
            w:perform_action(
              act.SwitchToWorkspace({ name = name, spawn = { cwd = wezterm.home_dir } }),
              p
            )
          end
        end),
      }),
      pane
    )
    return
  end

  local name = id:match("[^/]+$") or id
  window:perform_action(act.SwitchToWorkspace({ name = name, spawn = { cwd = id } }), pane)
end

--------------- schema processor ---------------

local function complete_schema(schema)
  if type(schema.processing) == "function" then schema.processing = { schema.processing } end

  local defaults = {
    options = {
      title = "workspaces",
      always_fuzzy = true,
      callback = sessionizer.DefaultCallback,
    },
    processing = {},
  }
  merge_tables(defaults, schema)
  return defaults
end

local function evaluate_schema(schema)
  schema = complete_schema(schema)
  local result = {}

  for key, value in pairs(schema) do
    if key ~= "processing" and key ~= "options" then
      if type(value) == "string" then
        table.insert(result, { label = value, id = value })
      elseif type(value) == "table" then
        if value.label and value.id then
          table.insert(result, value)
        else -- nested schema
          append_each(evaluate_schema(value), result)
        end
      elseif type(value) == "function" then -- generator
        append_each(evaluate_schema(value()), result)
      end
    end
  end

  for _, processor in ipairs(schema.processing) do
    processor(result)
  end

  return result
end

--------------- generators ---------------

-- Entry that prompts for a name and opens a fresh workspace in $HOME.
sessionizer.NewWorkspace = function(opts)
  local entry = { label = "+ new workspace", id = NEW_WORKSPACE_ID }
  merge_tables(entry, opts)
  return function()
    return { entry }
  end
end

-- Git repositories under a path, found with fd. Accepts a plain path
-- string or { path, fd_path?, max_depth?, extra_args? }.
sessionizer.FdSearch = function(opts)
  if type(opts) == "string" then opts = { opts } end

  return function()
    local defaults = {
      fd_path = "/opt/homebrew/bin/fd",
      max_depth = 4,
      extra_args = {},
    }
    merge_tables(defaults, opts)
    opts = defaults

    local command = {
      opts.fd_path,
      "-HI",
      "-td",
      "^.git$",
      "--max-depth=" .. opts.max_depth,
      "--format", "{//}",
    }
    append_each(opts.extra_args, command)
    table.insert(command, opts[1])

    local success, stdout, stderr = wezterm.run_child_process(command)
    if not success then
      wezterm.log_error("sessionizer: fd failed: " .. (stderr or ""))
      return {}
    end

    local entries = {}
    for line in stdout:gmatch("[^\n]+") do
      table.insert(entries, { label = line, id = line })
    end
    return entries
  end
end

-- Currently open workspaces. Skips the active one unless
-- opts.filter_current = false, in which case it is listed first and
-- dimmed with a "(current)" marker.
sessionizer.AllActiveWorkspaces = function(opts)
  opts = opts or {}
  return function()
    local current = wezterm.mux.get_active_workspace()
    local entries = {}
    for _, name in ipairs(wezterm.mux.get_workspace_names()) do
      if name == current then
        if opts.filter_current == false then
          local label = wezterm.format({
            { Foreground = { Color = "#6e6a86" } }, -- rose-pine muted
            { Text = name .. " (current)" },
          })
          table.insert(entries, 1, { label = label, id = name })
        end
      else
        table.insert(entries, { label = name, id = name })
      end
    end
    return entries
  end
end

--------------- processing ---------------

-- Telescope-style labels ("filename_first"): "name   group" — name in
-- normal text (foam when its workspace is already open), group column
-- dimmed and aligned. Open workspaces sort first, then by group and
-- name. Optional opts.icon is
-- prefixed to each name. Non-path entries (e.g. NewWorkspace) stay at
-- the top untouched.
sessionizer.GroupedLabels = function(opts)
  opts = opts or {}
  local icon = opts.icon
  local colors = {
    icon = "#908caa",   -- rose-pine subtle
    group = "#6e6a86",  -- rose-pine muted
    active = "#9ccfd8", -- rose-pine foam
  }
  merge_tables(colors, opts.colors)

  return function(entries)
    local root = (opts.root or wezterm.home_dir):gsub("/$", "")

    local active = {}
    for _, name in ipairs(wezterm.mux.get_workspace_names()) do
      active[name] = true
    end

    local head, repos = {}, {}
    for _, entry in ipairs(entries) do
      if entry.id:sub(1, 1) == "/" then
        local name = entry.id:match("[^/]+$") or entry.id
        local rel = entry.id:gsub("^" .. root .. "/", "")
        local group = rel:match("^(.+)/[^/]+$") or ""
        table.insert(repos, { entry = entry, name = name, group = group })
      else
        table.insert(head, entry)
      end
    end

    table.sort(repos, function(a, b)
      local a_active = active[a.name] or false
      local b_active = active[b.name] or false
      if a_active ~= b_active then return a_active end
      if a.group ~= b.group then return a.group < b.group end
      return a.name < b.name
    end)

    local max_name = 0
    for _, r in ipairs(repos) do
      if #r.name > max_name then max_name = #r.name end
    end

    for i = #entries, 1, -1 do entries[i] = nil end
    append_each(head, entries)
    for _, r in ipairs(repos) do
      local segments = {}
      if icon then
        table.insert(segments, { Foreground = { Color = colors.icon } })
        table.insert(segments, { Text = icon })
      end
      if active[r.name] then
        table.insert(segments, { Foreground = { Color = colors.active } })
      else
        table.insert(segments, "ResetAttributes")
      end
      table.insert(segments, { Text = r.name })
      if r.group ~= "" then
        table.insert(segments, { Foreground = { Color = colors.group } })
        table.insert(segments, { Text = string.rep(" ", max_name - #r.name) .. "  " .. r.group })
      end
      r.entry.label = wezterm.format(segments)
      table.insert(entries, r.entry)
    end
  end
end

-- Colors entries whose workspace is already open. Run it after any
-- processing that rewrites labels, or the color escapes get clobbered.
sessionizer.HighlightActive = function(opts)
  opts = opts or {}
  local color = opts.color or "#9ccfd8" -- rose-pine foam
  return function(entries)
    local active = {}
    for _, name in ipairs(wezterm.mux.get_workspace_names()) do
      active[name] = true
    end
    for _, entry in ipairs(entries) do
      local name = entry.id:match("[^/]+$") or entry.id
      if active[name] then
        entry.label = wezterm.format({
          { Foreground = { Color = color } },
          { Text = entry.label },
        })
      end
    end
  end
end

--------------- public api ---------------

sessionizer.show = function(schema)
  return wezterm.action_callback(function(window, pane)
    local entries = evaluate_schema(schema)
    local options = complete_schema(schema).options
    window:perform_action(
      act.InputSelector({
        title = options.title,
        description = options.prompt,
        fuzzy_description = options.prompt,
        fuzzy = options.always_fuzzy,
        choices = entries,
        action = wezterm.action_callback(options.callback),
      }),
      pane
    )
  end)
end

--------------- fzf backend ---------------

-- Workspace switching is a GUI-only action, so the fzf window reports
-- the pick back through an OSC 1337 SetUserVar escape; this handler
-- receives it (value arrives base64-decoded) and runs the schema
-- callback against the window the picker was opened from — not the
-- popup, which is already closing.
local FZF_VAR = "sessionizer_select"
local SWITCH_SENTINEL = "__switch__"
local fzf_callback = nil
local fzf_on_tab = nil
local fzf_origin_window_id = nil

wezterm.on("user-var-changed", function(_, _, name, value)
  if name ~= FZF_VAR or value == "" or not fzf_callback then return end

  local origin = nil
  for _, w in ipairs(wezterm.gui.gui_windows()) do
    if w:window_id() == fzf_origin_window_id then
      origin = w
      break
    end
  end
  if not origin then
    wezterm.log_error("sessionizer: origin window is gone")
    return
  end

  -- Tab pressed in the modal: open the alternate picker instead.
  if value == SWITCH_SENTINEL then
    if fzf_on_tab then fzf_on_tab(origin, origin:active_pane()) end
    return
  end

  fzf_callback(origin, origin:active_pane(), value, value)
end)

-- Same schema as show(), rendered with fzf in a small centered modal
-- window instead of the InputSelector overlay. Gains vim-style paging
-- (ctrl-d/ctrl-u) and ctrl-j/k movement; Esc closes the modal. Extra
-- options: fzf_path, background (modal window background color),
-- on_tab (function(window, pane) run when Tab is pressed in the modal
-- — used to toggle to an alternate picker; the modal closes first).
sessionizer.show_fzf = function(schema)
  return wezterm.action_callback(function(window, _)
    local entries = evaluate_schema(schema)
    local options = complete_schema(schema).options
    fzf_callback = options.callback
    fzf_on_tab = options.on_tab
    fzf_origin_window_id = window:window_id()

    local tmp = "/tmp/wezterm-sessionizer-entries"
    local f = io.open(tmp, "w")
    if not f then
      wezterm.log_error("sessionizer: cannot write " .. tmp)
      return
    end
    for _, entry in ipairs(entries) do
      f:write(entry.label .. "\t" .. entry.id .. "\n")
    end
    f:close()

    local fzf = options.fzf_path or "/opt/homebrew/bin/fzf"
    local send_var = "printf '\\033]1337;SetUserVar=" .. FZF_VAR .. "=%s\\007'"
    local fzf_cmd = fzf
      .. " --ansi --reverse --delimiter='\\t' --with-nth=1"
      .. " --prompt='" .. (options.prompt or "> ") .. "'"
      .. " --bind='ctrl-d:half-page-down,ctrl-u:half-page-up'"
      .. (options.on_tab and " --expect=tab" or "")
      .. (options.fzf_args and (" " .. options.fzf_args) or "")
      .. " < " .. tmp

    local script
    if options.on_tab then
      -- --expect makes fzf print the pressed key on line 1 and the
      -- selection on line 2; Tab reports back a switch sentinel.
      script = table.concat({
        "out=$(" .. fzf_cmd .. ")",
        "rm -f " .. tmp,
        "key=$(printf '%s\\n' \"$out\" | head -n1)",
        "selected=$(printf '%s\\n' \"$out\" | sed -n 2p)",
        'if [ "$key" = "tab" ]; then',
        "  " .. send_var .. " \"$(printf '%s' '" .. SWITCH_SENTINEL .. "' | base64)\"",
        "  sleep 0.2", -- let wezterm parse the escape before the pane dies
        'elif [ -n "$selected" ]; then',
        "  id=$(printf '%s' \"$selected\" | cut -f2-)",
        "  " .. send_var .. " \"$(printf '%s' \"$id\" | base64)\"",
        "  sleep 0.2",
        "fi",
      }, "\n")
    else
      script = table.concat({
        "selected=$(" .. fzf_cmd .. ")",
        "rm -f " .. tmp,
        'if [ -n "$selected" ]; then',
        "  id=$(printf '%s' \"$selected\" | cut -f2-)",
        "  " .. send_var .. " \"$(printf '%s' \"$id\" | base64)\"",
        "  sleep 0.2", -- let wezterm parse the escape before the pane dies
        "fi",
      }, "\n")
    end

    -- Size to the content: rows from the entry count, cols from the
    -- longest label (ANSI escapes stripped; multibyte glyphs count
    -- extra, which only errs on the wide side). Passed at spawn time —
    -- resizing/moving the window after it appears is what flickers.
    local cols = 0
    for _, entry in ipairs(entries) do
      local plain = entry.label:gsub("\27%[[%d;:]*m", "")
      if #plain > cols then cols = #plain end
    end
    cols = math.max(40, math.min(cols + 4, 120))
    local rows = math.max(3, math.min(#entries + 2, 30))

    -- Pixel estimate of the final window, to center it at spawn.
    -- font_zoom is maintained by the zoom keybindings (keys.lua) so the
    -- modal follows the terminal's zoom level.
    local zoom = 1.1 ^ (wezterm.GLOBAL.font_zoom or 0)
    local font = window:effective_config().font_size * zoom
    local cell_w, cell_h = font * 0.62, font * 1.55
    local screen = wezterm.gui.screens().active
    local w = math.floor(cols * cell_w) + 24
    local h = math.floor(rows * cell_h) + 16

    local _, _, mux_window = wezterm.mux.spawn_window({
      args = { "/bin/sh", "-c", script },
      width = cols,
      height = rows,
      position = {
        x = math.floor(screen.x + (screen.width - w) / 2),
        y = math.floor(screen.y + (screen.height - h) / 3),
        origin = "ScreenCoordinateSystem",
      },
    })

    local gui = mux_window:gui_window()
    if gui then
      local overrides = {
        enable_tab_bar = false,
        window_decorations = "RESIZE",
        exit_behavior = "Close",
        window_padding = { left = 12, right = 12, top = 8, bottom = 8 },
        font_size = font,
      }
      if options.background then
        overrides.colors = { background = options.background }
      end
      gui:set_config_overrides(overrides)
      -- spawn-time position is not reliably honored; correct it here
      gui:set_position(
        math.floor(screen.x + (screen.width - w) / 2),
        math.floor(screen.y + (screen.height - h) / 3)
      )
    end
  end)
end

return sessionizer
