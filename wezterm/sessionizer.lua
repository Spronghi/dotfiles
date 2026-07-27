local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local fd = "/opt/homebrew/bin/fd"
local rootPath = "/Users/simonecolaci/workspace"

M.toggle = function(window, pane)
  local success, stdout, stderr = wezterm.run_child_process({
    fd, "-HI", "-td", "^.git$", "--max-depth=4", rootPath,
  })

  if not success then
    wezterm.log_error("Failed to run fd: " .. stderr)
    return
  end

  local raw = {}
  for line in stdout:gmatch("([^\n]*)\n?") do
    if line ~= "" then
      local path  = line:gsub("/.git/?$", "")
      local name  = path:match("[^/]+$") or path
      local rel   = path:gsub("^" .. rootPath .. "/", "")
      local group = rel:match("^(.+)/[^/]+$") or ""
      table.insert(raw, { path = path, name = name, group = group })
    end
  end

  table.sort(raw, function(a, b)
    if a.group ~= b.group then return a.group < b.group end
    return a.name < b.name
  end)

  local max_name = 0
  for _, p in ipairs(raw) do
    if #p.name > max_name then max_name = #p.name end
  end

  local choices = {
    { label = "+ new workspace", id = "__new__" },
  }

  for _, p in ipairs(raw) do
    local pad     = string.rep(" ", max_name - #p.name)
    local right   = p.group ~= "" and ("  ·  " .. p.group) or ""
    local display = p.name .. pad .. right

    table.insert(choices, {
      label = display,
      id    = p.name .. "\t" .. p.path,
    })
  end

  window:perform_action(
    act.InputSelector({
      action = wezterm.action_callback(function(win, inner_pane, id, _)
        if not id then return end

        if id == "__new__" then
          win:perform_action(
            act.PromptInputLine({
              description = "workspace name",
              action = wezterm.action_callback(function(w, p, name)
                if name and name ~= "" then
                  w:perform_action(
                    act.SwitchToWorkspace({
                      name = name,
                      spawn = { cwd = wezterm.home_dir },
                    }),
                    p
                  )
                end
              end),
            }),
            inner_pane
          )
          return
        end

        local name, path = id:match("^([^\t]+)\t(.+)$")
        if name and path then
          win:perform_action(
            act.SwitchToWorkspace({ name = name, spawn = { cwd = path } }),
            inner_pane
          )
        end
      end),
      fuzzy = true,
      title = "workspaces",
      choices = choices,
    }),
    pane
  )
end

return M
