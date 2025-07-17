
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        -- first key is the mode
        n = {
          -- second key is the lefthand side of the map
          -- mappings seen under group name "Buffer"
          ["<Leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
          ["<Leader>bD"] = {
            function()
              require("astroui.status").heirline.buffer_picker(function(bufnr)
                require("astrocore.buffer").close(bufnr)
              end)
            end,
            desc = "Pick to close",
          },
          -- tables with just a `desc` key will be registered with which-key if it's installed
          -- this is useful for naming menus
          ["<Leader>b"] = { desc = "Buffers" },
          ["<Leader>|"] = {desc = "Horozontal pane split", "<cmd>split<cr>"},
          ["<Leader>\\"] = {desc = "Vertical pane split", "<cmd>vsplit<cr>"},
          ["<Leader>e"] = {desc = "Oil", "<cmd>Oil --float<cr>"},
          -- vim.keymaps.set("n", "-", require("oil").open, { desc = "Open parent directory" })

          -- ["<Leader>tt"] = {"<cmd>ToggleTerm direction=horizontal<cr>", desc = "Toggle Terminal"},
          -- quick save
          -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
        },
        t = {
          -- setting a mapping to false will disable it
          -- ["<esc>"] = false,
        },
      },
    },
  },
}
