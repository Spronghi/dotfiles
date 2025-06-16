local options = { noremap = true, silent = true }

vim.keymap.set("n", "<C-h>", ":wincmd h<CR>", options)
vim.keymap.set("n", "<C-j>", ":wincmd j<CR>", options)
vim.keymap.set("n", "<C-k>", ":wincmd k<CR>", options)
vim.keymap.set("n", "<C-l>", ":wincmd l<CR>", options)
