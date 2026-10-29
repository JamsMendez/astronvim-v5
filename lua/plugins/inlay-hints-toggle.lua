-- One global toggle for everything rendered as inline hints:
-- LSP inlay hints, lsp-lens usages/implementations, and SQL column hints.
-- It is global (astrocore) instead of LSP-attached because SQL buffers have
-- no language server to register it. All of them start hidden.

local function toggle()
  require("astrolsp.toggles").inlay_hints()
  local enabled = vim.lsp.inlay_hint.is_enabled()
  local lens = require "lsp-lens.lens-util"
  if enabled then
    lens:lsp_lens_on()
  else
    lens:lsp_lens_off()
  end
  require("sql_param_hints").set(enabled)
end

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          ["<Leader>uH"] = { toggle, desc = "Toggle inlay hints, lenses and SQL hints (global)" },
        },
      },
      autocmds = {
        sql_param_hints = {
          {
            event = "FileType",
            pattern = "sql",
            desc = "Attach SQL column hints",
            callback = function(args) require("sql_param_hints").attach(args.buf) end,
          },
        },
      },
    },
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      mappings = {
        n = {
          -- Drop the LSP-attached default so it cannot shadow the global toggle.
          ["<Leader>uH"] = false,
        },
      },
    },
  },
}
