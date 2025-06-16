return {
  "tpope/vim-fugitive",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  event = "VeryLazy",
  init = function()
    require("which-key").add({
      { "<leader>g",  group = "fugitive" },
      { "<leader>gg", "<cmd>Git<cr>",       desc = "Git" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
      { "<leader>ga", "<cmd>Git add .<cr>", desc = "Git add ." },
      { "<leader>gc", "<cmd>GcLog<cr>",     desc = "GcLog" },
      {
        "<leader>gu",
        function()
          local confirm = vim.fn.input("Are you sure you want to undo the last commit? (y/N) ")
          local command = string.format('Git reset HEAD^')

          if string.lower(confirm) ~= "y" then
            return
          end

          vim.cmd(command)
        end,
        desc = "Git reset HEAD^"
      },
    })
  end
}
