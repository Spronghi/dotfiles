return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = false,
  config = function()
    require("harpoon"):setup({})

    --enabe_tag_on_every_visited_file()
  end,
  init = function()
    require("which-key").add({
      {
        "<leader>a",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Add to harpoon"
      },
      {
        "<leader>e",
        function()
          local harpoon = require("harpoon")

          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Open harpoon"
      },
      {
        "[[",
        function()
          require("harpoon"):list():prev()
        end,
        desc = "Harpoon prev"
      },
      {
        "]]",
        function()
          require("harpoon"):list():next()
        end,
        desc = "Harpoon next"
      }

    })
  end
}
