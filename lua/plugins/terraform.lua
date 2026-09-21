---@type LazySpec
return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      -- Install terraform-ls and let AstroLSP enable it for Terraform buffers.
      ensure_installed = { "terraformls" },
    },
  },
}
