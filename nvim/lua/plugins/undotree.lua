return {
  "mbbill/undotree",
  init = function()
    require("which-key").add({
      { "<leader>u", vim.cmd.UndotreeToggle, desc = "undotree" }
    })
  end
}
