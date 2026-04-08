--- *wip.formatter* Formatter setup
---
--- Registers formatter mappings with conform.nvim for each file type.

local M = {}

--- Configures conform.nvim formatter mappings for each file type.
---@private
---@param formatters_map table<string, string[]> Mapping of file type to formatter names
M.setup = function(formatters_map)
  local conform = require("conform")
  for ft, formatters in pairs(formatters_map) do
    conform.formatters_by_ft[ft] = formatters
  end
end

return M
