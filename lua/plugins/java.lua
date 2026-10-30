-- Java overrides on top of astrocommunity.pack.java (nvim-jdtls)

local root_markers = { ".git", "mvnw", "gradlew" }

-- sha256 of astrocommunity's pack/java/init.lua when the config override below was last reviewed.
-- On mismatch, compare upstream's `config` with ours, then update this value (`sha256sum <file>`).
local reviewed_pack_sha256 = "558cbeb89c05104ee098d3d59143c58105daa817ed3a57f6f5a9a9b5d742b61b"

local function check_pack_update(notify)
  local path = require("lazy.core.config").plugins.astrocommunity.dir .. "/lua/astrocommunity/pack/java/init.lua"
  local file = io.open(path, "rb")
  if not file then return notify("jdtls: astrocommunity Java pack not found:\n" .. path, vim.log.levels.WARN) end
  local content = file:read "*a"
  file:close()
  if vim.fn.sha256(content) ~= reviewed_pack_sha256 then
    notify(
      "astrocommunity Java pack changed since the jdtls config override was reviewed.\nReview:\n"
        .. path
        .. "\nthen update `reviewed_pack_sha256` in lua/plugins/java.lua",
      vim.log.levels.WARN
    )
  end
end

-- jdtls imports Maven/Gradle projects, which executes their build scripts (build.gradle, gradlew).
-- It only starts in project roots trusted in Neovim's trust database (`:h vim.secure.read()`):
-- answer the prompt with (a)llow, or use `:JavaTrust` / `:JavaUntrust` from a Java buffer.

---@type LazySpec
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- drop full LSP protocol logging: it writes every request (including source) to the workspace log
      opts.cmd = vim.tbl_filter(
        function(arg) return arg ~= "-Dlog.protocol=true" and arg ~= "-Dlog.level=ALL" end,
        opts.cmd
      )
    end,
    -- replaces the pack's config to gate jdtls startup behind project trust
    config = function(_, opts)
      local notify = require("astrocore").notify
      local prompted = {} -- roots already prompted this session, so ignoring the prompt is not repeated
      check_pack_update(notify)

      local function start(bufnr, root)
        require("jdtls").start_or_attach(vim.tbl_extend("force", opts, { root_dir = root }), {}, { bufnr = bufnr })
      end

      local function buf_root(bufnr)
        local root = vim.fs.root(bufnr, root_markers)
        if not root then notify("jdtls: root_dir not found. Please specify a root marker", vim.log.levels.ERROR) end
        return root
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function(args)
          local root = buf_root(args.buf)
          if not root or prompted[root] then return end
          -- prompts only when the root has no persisted allow/deny decision
          if vim.secure.read(root) then return start(args.buf, root) end
          prompted[root] = true
          notify(
            "jdtls: not started, project root is not trusted:\n" .. root .. "\nRun `:JavaTrust` to enable it.",
            vim.log.levels.WARN
          )
        end,
      })

      vim.api.nvim_create_user_command("JavaTrust", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local root = buf_root(bufnr)
        if not root then return end
        local ok, err = vim.secure.trust { action = "allow", path = root }
        if not ok then return notify("jdtls: " .. err, vim.log.levels.ERROR) end
        prompted[root] = nil
        if vim.bo[bufnr].filetype == "java" then start(bufnr, root) end
        notify("jdtls: trusted " .. root)
      end, { desc = "Trust the current Java project root and start jdtls" })

      vim.api.nvim_create_user_command("JavaUntrust", function()
        local root = buf_root(0)
        if not root then return end
        local ok, err = vim.secure.trust { action = "remove", path = root }
        if not ok then return notify("jdtls: " .. err, vim.log.levels.ERROR) end
        notify("jdtls: removed trust for " .. root .. "\nRestart Neovim to stop the running server.")
      end, { desc = "Remove trust for the current Java project root" })

      -- load main class configs once jdtls is attached (see nvim-jdtls#nvim-dap-configuration)
      vim.api.nvim_create_autocmd("LspAttach", {
        pattern = "*.java",
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "jdtls" then require("jdtls.dap").setup_dap_main_class_configs() end
        end,
      })
    end,
  },
}
