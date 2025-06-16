-- https://codecompanion.olimorris.dev/
return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      display = {
        chat = {
          window = {
            position = "right", -- left|right|top|bottom (nil will default depending on vim.opt.plitright|vim.opt.splitbelow)
          },
        },
      },
    })

    require("which-key").add({
      { "<leader>c",  group = "code companion" },
      { "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", desc = "code companion chat" },
      { "<leader>ca", "<cmd>CodeCompanionActions<cr>",     desc = "code companion actions" },
    })

    require("which-key").add({
      mode = { "v" },
      { "<leader>c",  group = "code companion" },
      { "<leader>cc", ":CodeCompanion ",           desc = "code companion command" },
      { "<leader>ca", ":CodeCompanionActions<cr>", desc = "code companion actions" },
    })
  end,
}
