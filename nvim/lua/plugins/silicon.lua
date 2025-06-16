return {
  "michaelrommel/nvim-silicon",
  lazy = true,
  cmd = "Silicon",
  init = function()
    require("which-key").add({
      mode = { "v" },
      { "<leader>s",  group = "silicon" },
      { "<leader>ss", function() require("nvim-silicon").clip({ language = "markdown" }) end, desc = "Copy JS code screenshot to clipboard" },
    })
  end,
  opts = {
    disable_defaults = true,
    background = "#00000000",
    pad_horiz = 0,
    pad_vert = 0,
    language = function()
      return vim.bo.filetype
    end,
  }
}
