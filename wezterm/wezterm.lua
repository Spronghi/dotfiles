local wezterm = require("wezterm")

-- custom configs
local keys = require("configs.keys")
local colors = require("configs.theme")
local wsl_domains = require("configs.wsl_domains")
local startup = require("configs.startup")

-- init the table that will hold the configuration.
local config = {}

-- init the wezterm configs
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.bypass_mouse_reporting_modifiers = "ALT"

-- set theme like font, color scheme and this kind of stuff
colors(config)

-- setup custom keys
keys(config)

-- setup WSL specific logic
wsl_domains(config)

startup(config)

-- and finally, return the configuration to wezterm
return config
