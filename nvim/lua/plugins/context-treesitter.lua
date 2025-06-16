return {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = {
    "nvim-treesitter/nvim-treesitter"
  },
  opts = {
    enable = true,
    max_lines = 1, -- How many lines the window should span. Values <= 0 mean no limit.
  },
}
