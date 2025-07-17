
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = {
      position = "left",
    },

    filesystem = {
      filtered_items = {
        visible = true,
        show_hidden_count = true,
        hide_gitignored = false,
        hide_dotfiles = false,
        hide_by_name = {
          '.git'
        },
      },
    },
  }
}
