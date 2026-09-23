---@type LazySpec
-- Workaround: astrolsp / nvim-lspconfig / mason-lspconfig are lazy-loaded on
-- the `User AstroFile` event, so for the FIRST file opened (e.g. `nvim main.tf`)
-- the FileType event runs before the Terraform language server has been enabled
-- and the automatic LSP attach is missed. This re-attaches the server once the
-- config becomes available.
local function ensure_terraformls_attached(bufnr)
  local tries = 0
  local timer = vim.uv.new_timer()
  -- uv timer callbacks run in a "fast event" context where most nvim_* API
  -- calls are forbidden, so only schedule() is allowed inside the timer.
  timer:start(150, 150, function()
    tries = tries + 1
    if tries > 30 then
      timer:close() -- give up after ~4.5s
      return
    end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        timer:close()
        return
      end
      local cfg = vim.lsp.config["terraformls"]
      if not cfg or not vim.lsp.is_enabled("terraformls") then return end -- not ready yet, retry
      timer:close()
      if not vim.lsp.get_clients({ bufnr = bufnr, name = "terraformls" })[1] then
        vim.lsp.start(vim.deepcopy(cfg), { bufnr = bufnr, _root_markers = cfg.root_markers })
      end
    end)
  end)
end

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "terraform", "terraform-vars" },
  callback = function(args) ensure_terraformls_attached(args.buf) end,
})

return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      -- Install terraform-ls and let AstroLSP enable it for Terraform buffers.
      ensure_installed = { "terraformls" },
    },
  },
}

