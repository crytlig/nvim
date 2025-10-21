return {
  "neovim/nvim-lspconfig",
  config = function()
    local lspconfig = require('lspconfig')
    lspconfig.pylsp.setup {
      settings = {
        pylsp = {
          plugins = {
            pycodestyle = {
              enabled = false,
            },
          }
        },
      }
    }
  end,
}
