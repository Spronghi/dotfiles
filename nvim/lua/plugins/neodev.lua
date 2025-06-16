return {
  "folke/neodev.nvim",
  event = "BufEnter *.lua",
  opts = {
    library = { plugins = { "neotest" }, types = true },
  },
}
