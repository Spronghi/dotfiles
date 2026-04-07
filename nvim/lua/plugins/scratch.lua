return {
  "LintaoAmons/scratch.nvim",
  event = "VeryLazy",
  init = function()
    require("which-key").add({
      mode = { "n" },
      { "<leader>s", group = "scratch" },
      {
        "<leader>sf",
        function()
          require('telescope.builtin').find_files({ cwd = '~/.cache/nvim/scratch.nvim/', sorting_strategy = 'ascending', })
        end,
        desc = "Scratch find file"
      },
      -- { "<leader>sf",  "<cmd>ScratchOpen<cr>", desc = "Scratch find file" },
      {
        "<leader>ss",
        function()
          local format = vim.fn.input("format: ")

          if format == nil or format == "" then
            return
          end

          require("scratch").scratchByType(format)
        end,
        desc = "Scratch"
      },
      {
        "<leader>sj",
        function()
          require("scratch").scratchByType("json")
        end,
        desc = "Scratch json"
      },
    })
  end
}
