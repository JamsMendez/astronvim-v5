-- GoLand-style "N usages | N implementations" lenses above Go types.
-- gopls does not provide these code lenses, so lsp-lens computes them
-- client-side from textDocument/references and textDocument/implementation.

local SymbolKind = vim.lsp.protocol.SymbolKind

---@type LazySpec
return {
  { import = "astrocommunity.lsp.lsp-lens-nvim" },
  {
    "VidocqH/lsp-lens.nvim",
    ft = "go",
    opts = {
      enable = false, -- starts hidden, like inlay hints; see plugins/inlay-hints-toggle.lua
      include_declaration = false,
      hide_zero_counts = true,
      sections = {
        definition = false,
        git_authors = false,
        references = function(count) return count .. (count == 1 and " usage" or " usages") end,
        implements = function(count) return count .. (count == 1 and " implementation" or " implementations") end,
      },
      separator = "  ",
      target_symbol_kinds = { SymbolKind.Struct, SymbolKind.Interface },
    },
  },
}
