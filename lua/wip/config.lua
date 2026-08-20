--- *wip.config* Configuration parsing
---
--- Reads and aggregates `wip.config.json` into flat lists consumed by
--- the LSP, treesitter, formatter, and completion modules.

local M = {}

---@class ParsedConfig
---@field lsp_list string[]
---@field ft_list string[]
---@field formatters_map table<string, string[]>
---@field ts_list string[]

--- Appends every item that is not already present, preserving config order.
---@private
---@param list string[] List to append to, mutated in place
---@param items string[]|nil Items to append, may be nil
local function append_unique(list, items)
  if items == nil then
    return
  end
  for _, item in ipairs(items) do
    if not vim.list_contains(list, item) then
      list[#list + 1] = item
    end
  end
end

--- Parses a wip.config.json file and aggregates language settings into flat lists.
---@private
---@param file_path string Path to the wip.config.json file
---@return ParsedConfig
M.parse = function(file_path)
  local settings_file = assert(io.open(file_path))
  local settings_raw = settings_file:read("*a")
  settings_file:close()

  ---@type Settings
  local settings = vim.json.decode(settings_raw)

  return M.aggregate(settings)
end

--- Aggregates a decoded settings table into flat lists for each concern.
---
--- Languages that share a file type are merged rather than overwriting each
--- other, so every LSP, parser and formatter configured for a file type is
--- kept. Duplicates are dropped so nothing is installed or registered twice.
---@private
---@param settings Settings
---@return ParsedConfig
M.aggregate = function(settings)
  ---@type string[]
  local lsp_list = {}

  ---@type string[]
  local ft_list = {}

  ---@type table<string, string[]>
  local formatters_map = {}

  ---@type string[]
  local ts_list = {}

  for _, language in ipairs(settings.languages) do
    append_unique(ts_list, language.treesitters)
    append_unique(lsp_list, language.lsp)

    if language.file_types then
      for _, ft in ipairs(language.file_types) do
        if not vim.list_contains(ft_list, ft) then
          ft_list[#ft_list + 1] = ft
        end
        if language.formatters then
          formatters_map[ft] = formatters_map[ft] or {}
          append_unique(formatters_map[ft], language.formatters)
        end
      end
    end
  end

  return {
    lsp_list = lsp_list,
    ft_list = ft_list,
    formatters_map = formatters_map,
    ts_list = ts_list,
  }
end

return M
