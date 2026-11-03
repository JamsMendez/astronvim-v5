-- AstroDark with the GoLand-style semantic highlighting of the "goland" colorscheme.
-- UI, plugins and options (transparency, etc.) come from astrotheme's astrodark; only the
-- syntax roles GoLand distinguishes are remapped onto the astrodark palette:
--   declarations vs calls, exported vs local calls, packages, types, type parameters,
--   constants, builtin types and IntelliJ-style Java fields/annotations/modifiers.
-- Call coloring comes from after/queries/go/highlights.scm and gopls semantic tokens,
-- so keep `semanticTokens = true` in the gopls settings.

local astrotheme = require "astrotheme"
astrotheme.load "astrodark"
vim.g.colors_name = "astrodark-custom"

local c = require("astrotheme.lib.util").set_palettes(astrotheme.config)
local s = c.syntax

-- Blend two hex colors; t = 0 returns a, t = 1 returns b.
local function mix(a, b, t)
  local function ch(hex, i) return tonumber(hex:sub(i, i + 1), 16) end
  local out = "#"
  for _, i in ipairs { 2, 4, 6 } do
    out = out .. string.format("%02X", math.floor(ch(a, i) * (1 - t) + ch(b, i) * t + 0.5))
  end
  return out
end

local p = {
  fg = s.text,
  keyword = s.purple,
  func_decl = s.blue,
  func_call = mix(s.blue, s.text, 0.5), -- muted like GoLand's call color
  package = mix(s.green, s.text, 0.5), -- olive, distinct from strings
  type = s.yellow,
  type_param = s.cyan,
  constant = s.red,
  field = mix(s.red, s.text, 0.35),
  label = s.cyan,
  attribute = s.orange,
}

local groups = {
  -- Treesitter
  ["@variable.parameter"] = { fg = p.fg },
  ["@variable.member"] = { fg = p.fg },
  ["@property"] = { fg = p.fg },
  ["@constant"] = { fg = p.constant, italic = true },
  ["@constant.builtin"] = { fg = p.keyword },
  ["@module"] = { fg = p.package },
  ["@module.builtin"] = { fg = p.package },
  ["@label"] = { fg = p.label },
  ["@type"] = { fg = p.type },
  ["@type.definition"] = { fg = p.type },
  ["@type.builtin"] = { fg = p.keyword },
  ["@attribute"] = { fg = p.attribute },
  ["@function"] = { fg = p.func_decl },
  ["@function.builtin"] = { fg = p.func_decl },
  ["@function.method"] = { fg = p.func_decl },
  ["@function.call"] = { fg = p.func_call },
  ["@function.method.call"] = { fg = p.func_call },
  ["@constructor"] = { fg = p.fg },
  -- Go calls to local unexported funcs (`run(...)`, `stop()`) stay plain, like GoLand
  ["@goland.call.local"] = { fg = p.fg },

  -- LSP semantic tokens (gopls). Function/method calls are left to treesitter so the
  -- exported-call color wins; declarations and references come from gopls.
  ["@lsp.type.namespace"] = { fg = p.package },
  ["@lsp.type.type"] = { fg = p.type },
  ["@lsp.type.class"] = { fg = p.type },
  ["@lsp.type.struct"] = { fg = p.type },
  ["@lsp.type.interface"] = { fg = p.type },
  ["@lsp.type.enum"] = { fg = p.type },
  ["@lsp.type.typeParameter"] = { fg = p.type_param },
  ["@lsp.type.parameter"] = { fg = p.fg },
  ["@lsp.type.variable"] = { fg = p.fg },
  ["@lsp.type.property"] = { fg = p.fg },
  ["@lsp.type.function"] = { fg = p.func_decl },
  ["@lsp.type.method"] = { fg = p.func_decl },
  ["@lsp.type.keyword"] = { fg = p.keyword },
  ["@lsp.type.modifier"] = { fg = p.keyword },
  ["@lsp.type.label"] = { fg = p.label },
  ["@lsp.type.operator"] = {},
  ["@lsp.type.comment"] = {},
  -- gopls marks constants as readonly; jdtls marks every `final` symbol readonly, so keep it Go-only
  ["@lsp.mod.readonly.go"] = { fg = p.constant, italic = true },
  ["@lsp.typemod.variable.readonly.java"] = { fg = p.fg },
  -- jdtls (IntelliJ Java colors): fields tinted, static fields and enum constants italic
  ["@lsp.type.property.java"] = { fg = p.field },
  ["@lsp.typemod.property.static.java"] = { fg = p.constant, italic = true },
  ["@lsp.type.enumMember.java"] = { fg = p.constant, italic = true },
  ["@lsp.type.annotation.java"] = { fg = p.attribute },
  ["@lsp.type.annotationMember.java"] = { fg = p.fg },
  ["@lsp.typemod.variable.defaultLibrary"] = { fg = p.keyword },
  ["@lsp.typemod.type.defaultLibrary"] = { fg = p.keyword },
  ["@lsp.typemod.function.defaultLibrary"] = { fg = p.func_decl },
  ["@lsp.typemod.function.definition"] = { fg = p.func_decl },
  ["@lsp.typemod.method.definition"] = { fg = p.func_decl },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end
