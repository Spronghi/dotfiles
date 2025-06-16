local module = {}

function module.dump(o)
  if type(o) == "table" then
    local s = "{ "
    for k, v in pairs(o) do
      if type(k) ~= "number" then k = '"' .. k .. '"' end
      s = s .. "[" .. k .. "] = " .. module.dump(v) .. ","
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

function module.getOS()
  -- ask LuaJIT first
  if jit then
    return jit.os
  end

  -- Unix, Linux variants
  local fh = assert(io.popen("uname -o 2>/dev/null", "r"))
  local osname = "Windows"

  if fh then
    osname = fh:read()
  end

  return osname
end

function module.is_osx()
  return module.getOS() == "OSX"
end

function module.is_linux()
  return module.getOS() == "Linux"
end

function module.is_unix()
  return package.config:sub(1, 1) == "/"
end

function module.is_windows()
  return package.config:sub(1, 1) == "\\"
end

function module.is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == "true"
end

return module
