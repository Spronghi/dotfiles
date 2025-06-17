return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    -- "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local lualine = require("lualine")

    -- Color table for highlights
    -- stylua: ignore
    local colors = {
      bg         = "#00FFFFFF",
      fg         = "#bbc2cf",
      yellow     = "#ECBE7B",
      cyan       = "#008080",
      darkblue   = "#081633",
      green      = "#98be65",
      orange     = "#FF8800",
      orange_ayu = "#EB8536",
      violet     = "#a9a1e1",
      rose       = "#eb6f92",
      magenta    = "#c678dd",
      blue       = "#51afef",
      blue_ayu   = "#60b8d6",
      red        = "#ec5f67",
      azure      = "#31748f",
    }

    local conditions = {
      buffer_not_empty = function()
        return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
      end,
      hide_in_width = function()
        return vim.fn.winwidth(0) > 80
      end,
      check_git_workspace = function()
        local filepath = vim.fn.expand("%:p:h")
        local gitdir = vim.fn.finddir(".git", filepath .. ";")
        return gitdir and #gitdir > 0 and #gitdir < #filepath
      end,
    }

    -- Config
    local config = {
      options = {
        -- Disable sections and component separators
        component_separators = "",
        section_separators = "",
        theme = {
          -- We are going to use lualine_c an lualine_x as left and
          -- right section. Both are highlighted by c theme .  So we
          -- are just setting default looks o statusline
          normal = { c = { fg = colors.fg, bg = colors.bg } },
          inactive = { c = { fg = colors.fg, bg = colors.bg } },
        },
      },
      extensions = { "oil", "fugitive" },
      sections = {
        -- these are to remove the defaults
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        -- These will be filled later
        lualine_c = {},
        lualine_x = {},
      },
      inactive_sections = {
        -- these are to remove the defaults
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = {},
        lualine_x = {},
      },
    }

    local function ins_left(component)
      table.insert(config.sections.lualine_c, component)
    end

    local function ins_right(component)
      table.insert(config.sections.lualine_x, component)
    end

    ins_left {
      "filename",
      path = 1
    }

    ins_right {
      "diff",
      diff_color = {
        added = { fg = colors.green },
        modified = { fg = colors.orange },
        removed = { fg = colors.red },
      },
      cond = conditions.hide_in_width,
    }

    ins_right {
      "branch",
      icon = "",
      color = { fg = colors.blue_ayu, gui = "bold" },
    }

    ins_right {
      "diagnostics",
      sources = { "nvim_diagnostic" },
      diagnostics_color = {
        color_error = { fg = colors.red },
        color_warn = { fg = colors.yellow },
        color_info = { fg = colors.cyan },
      },
    }

    ins_right {
      -- Lsp server name .
      function()
        local clients = vim.lsp.get_clients()
        if next(clients) == nil then
          return ""
        end

        local c = {}
        for _, client in pairs(clients) do
          table.insert(c, client.name)
        end
        return table.concat(c, "|")
      end,
      icon = " ",
      color = { gui = "bold" },
    }


    ins_right { "progress" }

    ins_right {
      "o:encoding",
      fmt = string.upper,
      cond = conditions.hide_in_width,
      color = { gui = "bold" },
    }

    ins_right {
      "fileformat",
      fmt = string.upper,
      icons_enabled = false,
      color = { gui = "bold" },
    }

    lualine.setup(config)
  end
}
