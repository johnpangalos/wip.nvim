local M = {}

--- Installs missing treesitter parsers and creates FileType autocmds for syntax
--- highlighting and indentation.
--- @param ts_list string[]: list of treesitter parser names to install
--- @param ft_list string[]: list of file types to create autocmds for
M.setup = function(ts_list, ft_list)
  local ts = require("nvim-treesitter")

  --- @type table<string, boolean>
  local ts_map = {}
  for _, p in ipairs(ts.get_installed("parsers")) do
    ts_map[p] = true
  end

  for _, t in pairs(ts_list) do
    if ts_map[t] == nil then
      -- synchronous install with a max timeout of 5 minutes
      ts.install(t):wait(300000)
      ts_map[t] = true
    end
  end

  for _, ft in pairs(ft_list) do
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { ft },
      callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end
end

return M
