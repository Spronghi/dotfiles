return {
  "iamcco/markdown-preview.nvim",
  enable = false,
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = function() vim.fn["mkdp#util#install"]() end,
  init = function()
    require("which-key").add({
      { "<leader>md", ":MarkdownPreviewToggle<CR>", desc = "Markdown preview" }
    })
  end
}
