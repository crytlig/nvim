return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    opts.diagnostics = opts.diagnostics or {}
    opts.diagnostics.jump = opts.diagnostics.jump or {}

    -- Neovim 0.12 replaced diagnostic.jump.float with jump.on_jump.
    opts.diagnostics.jump.float = nil
    opts.diagnostics.jump.on_jump = function(_, bufnr)
      vim.diagnostic.open_float {
        bufnr = bufnr,
        scope = "cursor",
        focus = false,
      }
    end
  end,
}
