return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-neotest/nvim-nio",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",

    "nvim-neotest/neotest-go",
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-jest",
  },
  lazy = false,
  config = function()
    require("neotest").setup({
      discovery = {
        enabled = false,
      },
      adapters = {
        require("neotest-go"),
        require("neotest-vitest"),
        require("neotest-jest")({
          jestCommand = "npm test --",
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
        }),
      },
    })
  end,
  init = function()
    require("which-key").add({
      { "<leader>t", group = "neotest" },
      {
        "<leader>tt",
        function()
          require("neotest").run.run()
        end,
        desc = "Run one"
      },
      {
        "<leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run all"
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug"
      },
      {
        "<leader>ts",
        function()
          require("neotest").run.stop()
        end,
        desc = "Stop"
      },
      {
        "<leader>to",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "Show output"
      },
      {
        "<leader>tp",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Summary"
      },
      {
        "<leader>ta",
        function()
          require("neotest").run.attach()
        end,
        desc = "Attach"
      },
    })
  end
}
