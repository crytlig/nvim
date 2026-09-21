return {
  "AstroNvim/astrocore",
  opts = {
    treesitter = {
      -- AstroNvim v6 configures Treesitter through AstroCore.
      -- Add the parser used by Noice for regex command-line highlighting.
      ensure_installed = { "regex", "lua", "vim" },
    },
  },
}
