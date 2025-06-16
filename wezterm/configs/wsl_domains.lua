local utils = require("utils")

return function(config)
  if not utils.is_windows() then
    return
  end

  config.default_domain = "WSL:Ubuntu"

  config.wsl_domains = {
    {
      -- The name of this specific domain.  Must be unique amonst all types
      -- of domain in the configuration file.
      name = "WSL:Ubuntu",

      -- The name of the distribution.  This identifies the WSL distribution.
      -- It must match a valid distribution from your `wsl -l -v` output in
      -- order for the domain to be useful.
      distribution = "Ubuntu",

      -- The username to use when spawning commands in the distribution.
      -- If omitted, the default user for that distribution will be used.

      -- username = "hunter",

      -- The current working directory to use when spawning commands, if
      -- the SpawnCommand doesn"t otherwise specify the directory.

      -- default_cwd = "/tmp"

      -- The default command to run, if the SpawnCommand doesn"t otherwise
      -- override it.  Note that you may prefer to use `chsh` to set the
      -- default shell for your user inside WSL to avoid needing to
      -- specify it here

      default_prog = { "zsh" }
    },
  }
end
