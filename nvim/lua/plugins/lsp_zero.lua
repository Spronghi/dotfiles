return {
  -- lsp zero docs https://lsp-zero.netlify.app/v3.x/
  "vonheikemen/lsp-zero.nvim",
  branch = "v4.x",
  lazy = false,
  dependencies = {
    "neovim/nvim-lspconfig",

    -- formatting
    "stevearc/conform.nvim",

    -- Autocompletion and snippets
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-buffer",
    "L3MON4D3/LuaSnip",

    -- Mason
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  init = function()
    -- Reserve a space in the gutter
    -- This will avoid an annoying layout shift in the screen
    vim.opt.signcolumn = 'yes'

    require("which-key").add({
      { "K",  vim.lsp.buf.hover,                                desc = "hover infos" },
      { "gD", vim.lsp.buf.definition,                           desc = "go to definition" },
      { "gR", vim.lsp.buf.declaration,                          desc = "go to declaration" },
      { "gr", require("telescope.builtin").lsp_references,      desc = "show references" },
      { "gi", require("telescope.builtin").lsp_implementations, desc = "show implementations" },
      { "ca", vim.lsp.buf.code_action,                          desc = "code action" },
      { "rn", vim.lsp.buf.rename,                               desc = "rename" },
    })
  end,
  config = function()
    local cmp = require('cmp')
    local lsp_zero = require("lsp-zero")
    local conform = require("conform")

    require('luasnip.loaders.from_vscode').lazy_load()

    vim.opt.updatetime = 500

    -- Reserve a space in the gutter
    -- This will avoid an annoying layout shift in the screen
    vim.opt.signcolumn = 'yes'

    conform.setup({
      format_on_save = {
        -- These options will be passed to conform.format()
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        javascript = { "prettier", "eslint", stop_after_first = true },
        css = { "prettier" },
        typescript = { "prettier", "eslint", stop_after_first = true },
        markdown = { "prettier" },
        json = { "prettier" },
      },
    })

    lsp_zero.on_attach(function(client, bufnr)
      lsp_zero.default_keymaps({ buffer = bufnr })
      lsp_zero.highlight_symbol(client, bufnr)
      -- this will fuck up the constructor spaces
      -- lsp_zero.buffer_autoformat()
    end)

    lsp_zero.ui({
      float_border = 'rounded',
      sign_text = {
        error = '✘',
        warn = '▲',
        hint = '⚑',
        info = '»',
      },
    })

    -- Add cmp_nvim_lsp capabilities settings to lspconfig
    -- This should be executed before you configure any language server
    local lspconfig_defaults = require('lspconfig').util.default_config
    lspconfig_defaults.capabilities = vim.tbl_deep_extend(
      'force',
      lspconfig_defaults.capabilities,
      require('cmp_nvim_lsp').default_capabilities()
    )

    lsp_zero.omnifunc.setup({
      trigger = '<C-Space>',
      use_fallback = true,
      update_on_delete = true,
      -- You need Neovim v0.10 to use vim.snippet.expand
      expand_snippet = vim.snippet.expand
    })

    cmp.setup({
      sources = {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'luasnip' },
      },
      snippet = {
        expand = function(args)
          -- You need Neovim v0.10 to use vim.snippet
          vim.snippet.expand(args.body)
          -- require('luasnip').lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
      }),

      -- add borders to snippets
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
    })

    require('mason').setup({})
    require('mason-lspconfig').setup({
      -- Replace the language servers listed here
      -- with the ones you want to install
      ensure_installed = { 'lua_ls', 'rust_analyzer' },
      handlers = {
        function(server_name)
          require('lspconfig')[server_name].setup({})
        end,

        lua_ls = function()
          local lua_opts = lsp_zero.nvim_lua_ls()
          require("lspconfig").lua_ls.setup(lua_opts)
        end,
      },
    })
  end,
}
