-- GoLand-style inline hints for SQL INSERTs: shows the target column name
-- before each VALUES expression, e.g. `VALUES (email $1, password_hash $2)`.
-- No SQL language server provides these, so they are derived from the
-- Tree-sitter `sql` parse tree.

local M = {}

local ns = vim.api.nvim_create_namespace "sql_param_hints"
local augroup = vim.api.nvim_create_augroup("sql_param_hints", { clear = true })

M.enabled = false

local function column_names(list, bufnr)
  local names = {}
  for child in list:iter_children() do
    if child:type() == "column" then table.insert(names, vim.treesitter.get_node_text(child, bufnr)) end
  end
  return names
end

local function hint_row(list, columns, bufnr)
  local i = 0
  for expr in list:iter_children() do
    if expr:named() then
      i = i + 1
      local name = columns[i]
      if not name then return end
      local row, col = expr:start()
      vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
        virt_text = { { name, "LspInlayHint" }, { " " } },
        virt_text_pos = "inline",
      })
    end
  end
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if not M.enabled or vim.bo[bufnr].filetype ~= "sql" then return end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "sql")
  if not ok or not parser then return end
  local root = parser:parse()[1]:root()
  local query = vim.treesitter.query.parse("sql", "(insert) @insert")

  for _, insert in query:iter_captures(root, bufnr) do
    local columns, after_values = nil, false
    for child in insert:iter_children() do
      local kind = child:type()
      if kind == "keyword_values" then
        after_values = true
      elseif kind == "list" then
        if not after_values then
          columns = column_names(child, bufnr)
        elseif columns then
          hint_row(child, columns, bufnr)
        end
      end
    end
  end
end

--- Show or hide the hints in every loaded SQL buffer.
---@param enabled boolean
function M.set(enabled)
  M.enabled = enabled
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "sql" then M.refresh(bufnr) end
  end
end

function M.attach(bufnr)
  vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
    group = augroup,
    buffer = bufnr,
    callback = function(args) M.refresh(args.buf) end,
  })
  M.refresh(bufnr)
end

return M
