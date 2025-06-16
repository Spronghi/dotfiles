return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    icons = {
      mappings = false
    }
  },
  config = function()
    require("which-key").add({
      { "<leader>bc", ":bdelete!<CR>",               desc = "close current buffer" },
      { "<leader>bd", ":%bd|e#<CR>",                 desc = "close all open buffers" },
      { "<leader>l",  ":Lazy<CR>",                   desc = "lazy" },
      { "<leader>m",  ":Mason<CR>",                  desc = "mason" },
      { "<leader>h",  ":nohlsearch<CR>",             desc = "reset search" },
      { "<leader>py", ":let @+ = expand('%:t')<CR>", desc = "yank file name" },
      { "<leader>pv", vim.cmd.Oil,                   desc = "oil" },
    })
  end
}
