local utils = require("utils")
local mac_startup = require("configs.startup.mac")
local wsl_startup = require("configs.startup.wsl")

return function(config)
  if not utils.is_windows() and not utils.is_linux() then
    mac_startup(config)
  end

  if utils.is_windows() then
    wsl_startup(config)
  end
end
