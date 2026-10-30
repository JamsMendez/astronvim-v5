-- JavaScript/TypeScript overrides on top of astrocommunity.pack.typescript
--
-- Formatting and linting follow each project's own tooling:
--   * biome.json / biome.jsonc  -> biome LSP (lint + format)
--   * eslint config             -> eslint LSP (diagnostics and fixes, no formatting)
--   * prettier config           -> prettier from the project's node_modules only
--   * no config                 -> nothing formats, so foreign code is never reformatted
-- Do not install prettier through Mason: mason-null-ls would register it as a global formatter,
-- which loads a cloned repo's prettier.config.js and plugins before any `npm install`.

local js_filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

local prettier_config_files = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.json5",
  ".prettierrc.yaml",
  ".prettierrc.yml",
  ".prettierrc.toml",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.ts",
  ".prettierrc.cts",
  ".prettierrc.mts",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
  "prettier.config.cts",
  "prettier.config.mts",
}

-- per buffer, so each project (and each package of a monorepo) decides for itself
local function uses_prettier(bufname)
  local find_opts = { path = vim.fs.dirname(bufname), upward = true, type = "file", limit = 1 }
  if vim.fs.find(prettier_config_files, find_opts)[1] then return true end
  local package_json = vim.fs.find("package.json", find_opts)[1]
  if not package_json then return false end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
  return ok and type(decoded) == "table" and decoded.prettier ~= nil
end

---@type LazySpec
return {
  {
    "vuki656/package-info.nvim",
    -- autostart runs `<package manager> outdated` on entering package.json, which executes
    -- project code (e.g. pnpm loads the repo's .pnpmfile.cjs); run `:lua require("package-info").show()` manually instead
    opts = { autostart = false },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "biome", "eslint-lsp" })
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local null_ls = require "null-ls"
      opts.sources = require("astrocore").list_insert_unique(opts.sources, {
        null_ls.builtins.formatting.prettier.with {
          filetypes = js_filetypes,
          only_local = "node_modules/.bin",
          runtime_condition = function(params) return uses_prettier(params.bufname) end,
        },
      })
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    -- the default handler would register Mason's biome as a global formatter for every project;
    -- biome runs through its LSP instead, which only attaches where a biome config exists
    opts = { handlers = { biome = function() end } },
  },
  {
    "AstroNvim/astrolsp",
    opts = function(_, opts)
      local astrocore = require "astrocore"
      local formatting = opts.formatting
      formatting.format_on_save.allow_filetypes =
        astrocore.list_insert_unique(formatting.format_on_save.allow_filetypes, js_filetypes)
      -- biome or prettier own formatting; vtsls and eslint would rewrite the same buffer differently
      formatting.disabled = astrocore.list_insert_unique(formatting.disabled, { "vtsls", "eslint" })
    end,
  },
}
