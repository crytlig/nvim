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
      if timer:is_closing() then return end
      if not vim.api.nvim_buf_is_valid(bufnr) then
        timer:close()
        return
      end
      if not vim.lsp.is_enabled("terraformls") then return end -- not ready yet, retry
      timer:close()
      if not vim.lsp.get_clients({ bufnr = bufnr, name = "terraformls" })[1] then
        -- Re-run Neovim's own enable logic for this buffer so `root_dir`
        -- functions and client reuse behave exactly like a normal attach.
        pcall(vim.api.nvim_exec_autocmds, "FileType", { group = "nvim.lsp.enable", buffer = bufnr, modeline = false })
      end
    end)
  end)
end

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "terraform", "terraform-vars" },
  callback = function(args) ensure_terraformls_attached(args.buf) end,
})

-- Root each terraform-ls client at the Terraform module, never at the git
-- repo/worktree root. With the default markers ({ ".terraform", ".git" }) a
-- file in a module without `.terraform` rooted the server at the repo, making
-- terraform-ls index every module (incl. all `.worktrees/*` copies). That made
-- completion responses take seconds, and blink.cmp waits up to 2s for the LSP
-- before showing any menu at all.
local function terraform_root_dir(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if fname == "" then return end
  local file_dir = vim.fs.dirname(fname)
  local git_root = vim.fs.root(bufnr, ".git")
  local tf_root = vim.fs.root(bufnr, { ".terraform", ".terraform.lock.hcl" })
  -- Only accept an initialised module dir inside the current repo/worktree.
  if tf_root and (not git_root or #tf_root >= #git_root) then
    on_dir(tf_root)
  else
    on_dir(file_dir)
  end
end

-- :TfLspDebug — run this when completion "dies" to capture what's going on.
-- Output is shown via vim.notify and appended to stdpath("state")/tf-lsp-debug.log
vim.api.nvim_create_user_command("TfLspDebug", function()
  local buf = vim.api.nvim_get_current_buf()
  local lines = {}
  local function add(fmt, ...) lines[#lines + 1] = fmt:format(...) end
  local function flush()
    local text = table.concat(lines, "\n")
    vim.notify(text, vim.log.levels.INFO, { title = "TfLspDebug" })
    local f = io.open(vim.fn.stdpath "state" .. "/tf-lsp-debug.log", "a")
    if f then
      f:write(os.date "[%F %T]\n" .. text .. "\n\n")
      f:close()
    end
  end

  add("buf=%d ft=%s file=%s", buf, vim.bo[buf].filetype, vim.api.nvim_buf_get_name(buf))
  add("macro recording=%q (blink is DISABLED while recording)", vim.fn.reg_recording())
  add("vim.b.completion=%s", vim.inspect(vim.b[buf].completion))
  local ok_cfg, blink_cfg = pcall(require, "blink.cmp.config")
  if ok_cfg then
    local ok_en, en = pcall(blink_cfg.enabled)
    add("blink enabled()=%s", ok_en and tostring(en) or ("error: " .. tostring(en)))
  else
    add "blink.cmp not loaded"
  end

  local clients = vim.lsp.get_clients { bufnr = buf }
  if #clients == 0 then add "NO LSP clients attached to this buffer" end
  for _, c in ipairs(clients) do
    local pending = {}
    for _, req in pairs(c.requests or {}) do
      if req.type == "pending" then pending[req.method] = (pending[req.method] or 0) + 1 end
    end
    add(
      "client %s#%d stopped=%s root=%s pending=%s",
      c.name,
      c.id,
      tostring(c:is_stopped()),
      tostring(c.root_dir),
      vim.inspect(pending, { newline = "", indent = "" })
    )
  end

  local tfls = vim.lsp.get_clients({ bufnr = buf, name = "terraformls" })[1]
  if not tfls then
    flush()
    return
  end
  local params = vim.lsp.util.make_position_params(0, tfls.offset_encoding)
  local start = vim.uv.hrtime()
  local done = false
  tfls:request("textDocument/completion", params, function(err, result)
    done = true
    local ms = (vim.uv.hrtime() - start) / 1e6
    local items = result and (result.items or result) or {}
    add("completion at cursor: %.0f ms, %d items, err=%s", ms, #items, err and vim.inspect(err) or "nil")
    flush()
  end, buf)
  vim.defer_fn(function()
    if not done then
      add "completion at cursor: NO RESPONSE after 10s"
      flush()
    end
  end, 10000)
end, { desc = "Debug terraform-ls / blink.cmp completion state" })

return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      -- Install terraform-ls and let AstroLSP enable it for Terraform buffers.
      ensure_installed = { "terraformls" },
    },
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        terraformls = {
          root_dir = terraform_root_dir,
          init_options = {
            indexing = {
              -- never index git worktree copies of the repo
              ignoreDirectoryNames = { ".worktrees" },
            },
          },
        },
      },
    },
  },
}
