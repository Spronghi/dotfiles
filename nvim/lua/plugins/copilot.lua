return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  enabled = true,
  config = function()
    require('copilot').setup({
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        trigger_on_accept = true,
        keymap = {
          accept = "<C-CR>",
          next = "<M-]>",
          prev = "<M-[>",
          -- dismiss = "<C-x>"
        },
      },
    })
  end,
}
