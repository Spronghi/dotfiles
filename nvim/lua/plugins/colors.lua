local configs = require("configs")

local function set_transparent()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "none" })
end

if configs.color_scheme == "ayu" then
  return {
    "Shatur/neovim-ayu",
    name = "ayu",
    priority = 1000,
    config = function()
      require("ayu").setup({
        overrides = {
          Normal = { bg = "None" },
          ColorColumn = { bg = "None" },
          SignColumn = { bg = "None" },
          Folded = { bg = "None" },
          FoldColumn = { bg = "None" },
          CursorLine = { bg = "None" },
          CursorColumn = { bg = "None" },
          WhichKeyFloat = { bg = "None" },
          VertSplit = { bg = "None" },
        },
      })

      vim.cmd.colorscheme "ayu"

      set_transparent()
    end
  }
end

if configs.color_scheme == 'tokyo' then
  return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      set_transparent()
      vim.cmd.colorscheme "tokyonight-storm"
    end
  }
end

-- default is rose-pine
return {
  "rose-pine/neovim",
  name = "rose-pine",
  config = function()
    require("rose-pine").setup({
      styles = {
        italic = false,
        transparency = true,
      },
    })

    vim.cmd.colorscheme "rose-pine"

    set_transparent()
  end
}
