local function default_opts(additiona_opts)
  local opts = {
    layout_strategy = 'vertical',
    hidden = true,
    file_ignore_patterns = {
      ".git/", "^node_modules/"
    },
  }

  if additiona_opts then
    table.insert(opts, additiona_opts)
  end

  return opts
end

return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x", -- tag = "0.1.6",
  requires = { { "nvim-lua/plenary.nvim" } },
  config = function()
    require("telescope").setup({
      defaults = {
        file_sorter = require("telescope.sorters").get_fzy_sorter,
        path_display = { "filename_first" },
        -- layout_strategy = "horizontal",
        pickers = {
          git_files = default_opts(),
          live_grep = default_opts(),
          grep_string = default_opts(),
        }
      },
    })
  end,
  init = function()
    require("which-key").add({
      { "<leader>p",  group = "project" },
      { "<leader>h",  group = "help" },
      { "<leader>b",  group = "buffers" },
      { "gd",         require("telescope.builtin").lsp_definitions,       desc = "LSP Definitions" },
      { "<leader>po", require("telescope.builtin").lsp_document_symbols,  desc = "Document symbols" },
      { "<leader>pG", require("telescope.builtin").git_files,             desc = "Git files" },
      { "<leader>pw", require("telescope.builtin").lsp_workspace_symbols, desc = "Workspace symbols" },
      { "<leader>hf", require("telescope.builtin").help_tags,             desc = "Find help tags" },
      { "<leader>hc", require("telescope.builtin").commands,              desc = "Find commands" },
      { "<leader>px", require("telescope.builtin").diagnostics,           desc = "Diagnostics" },
      { "<leader>pr", require("telescope.builtin").resume,                desc = "Resume Search" },
      {
        "<leader>pg",
        function()
          require("telescope.builtin").grep_string({
            search = vim.fn.input("Grep > ")
          })
        end,
        desc = "Grep search"
      },
      {
        "<leader>pf",
        function()
          require("telescope.builtin").find_files(default_opts())
        end,
        desc = "Find file"
      },
      {
        "<leader>ps",
        function()
          require("telescope.builtin").live_grep(default_opts())
        end,
        desc = "Live grep"
      },
      {
        "<leader>bf",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Find buffers"
      },
    })
  end
}
