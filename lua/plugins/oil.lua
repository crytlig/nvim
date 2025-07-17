return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    keymaps = {
      ["-"] = false,
      ["<BS>"] = "actions.parent",
      ["<Esc>"] = "actions.close",
    },
    view_options = {
      show_hidden = true,
    },
    float = {
      padding = 4,
      max_height = 0.4,
      max_width = 0.4,
      preview_split = "right"
    },

    preview_win = {
      size = 30,
      update_on_cursor_moved = true,
      preview_method = "fast_scratch",
    },
  },
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  lazy = false,
}
