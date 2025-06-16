return {
  "stevearc/oil.nvim",
  opts = {
    win_options = {
      signcolumn = "number",
    },
    view_options = {
      -- Show files and directories that start with "."
      show_hidden = true,
    },
    keymaps = {
      ["<C-h>"] = false,
      ["<C-j>"] = false,
      ["<C-k>"] = false,
      ["<C-l>"] = false,
    }
  },
  dependencies = {
    -- "nvim-tree/nvim-web-devicons"
  },
}
