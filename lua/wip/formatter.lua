local M = {}

--- Configures conform.nvim formatter mappings for each file type.
--- @param formatters_map table<string, string[]>: mapping of file type to formatter names
M.setup = function(formatters_map)
  local conform = require("conform")
  for ft, formatters in pairs(formatters_map) do
    conform.formatters_by_ft[ft] = formatters
  end
end

return M
