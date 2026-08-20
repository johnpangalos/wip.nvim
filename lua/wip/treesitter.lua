--- *wip.treesitter* Treesitter setup
---
--- Installs missing treesitter parsers and creates FileType autocmds
--- for syntax highlighting and indentation.

local M = {}

--- Installs missing treesitter parsers and creates FileType autocmds for syntax
--- highlighting and indentation.
---@private
---@param ts_list string[] List of treesitter parser names to install
---@param ft_list string[] List of file types to create autocmds for
M.setup = function(ts_list, ft_list)
  local ts = require("nvim-treesitter")

  ---@type table<string, boolean>
  local ts_map = {}
  for _, p in ipairs(ts.get_installed("parsers")) do
    ts_map[p] = true
  end

  for _, t in ipairs(ts_list) do
    if ts_map[t] == nil then
      ts_map[t] = true
      -- A parser that fails to install must not stop the remaining ones,
      -- so each install is isolated. Synchronous, max timeout of 5 minutes.
      local ok, err = pcall(function()
        ts.install(t):wait(300000)
      end)
      if not ok then
        local msg = "wip.nvim: could not install parser " .. t .. ": " .. tostring(err)
        vim.schedule(function()
          vim.notify(msg, vim.log.levels.ERROR)
        end)
      end
    end
  end

  ---@type table<string, boolean>
  local ft_seen = {}
  for _, ft in ipairs(ft_list) do
    if ft_seen[ft] == nil then
      ft_seen[ft] = true
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { ft },
        callback = function()
          vim.treesitter.start()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end
  end
end

return M
