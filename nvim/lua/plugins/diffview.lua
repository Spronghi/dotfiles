return {
  "sindrets/diffview.nvim",
  opts = {
    view = {
      -- Configure the layout and behavior of different types of views.
      -- Available layouts:
      --  'diff1_plain'
      --    |'diff2_horizontal'
      --    |'diff2_vertical'
      --    |'diff3_horizontal'
      --    |'diff3_vertical'
      --    |'diff3_mixed'
      --    |'diff4_mixed'
      -- For more info, see |diffview-config-view.x.layout|.
      default = {
        -- Config for changed files, and staged files in diff views.
        -- layout = "diff3_mixed",
      },
    },
  },
  init = function()
    require("which-key").add({
      {
        "<leader>gd",
        "<cmd>DiffviewOpen<cr>",
        desc = "DiffviewOpen"
      },
    })
  end
}
