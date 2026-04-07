--- *wip.config* Configuration parsing
---
--- Reads and aggregates `wip.config.json` into flat lists consumed by
--- the LSP, treesitter, formatter, and completion modules.

local M = {}

--- @class ParsedConfig
--- @field lsp_list string[]
--- @field ft_list string[]
--- @field formatters_map table<string, string[]>
--- @field ts_list string[]

--- Parses a wip.config.json file and aggregates language settings into flat lists.
--- @param file_path string Path to the wip.config.json file
--- @return ParsedConfig
M.parse = function(file_path)
  local settings_file = assert(io.open(file_path))
  local settings_raw = settings_file:read("*a")
  settings_file:close()

  --- @type Settings
  local settings = vim.json.decode(settings_raw)

  return M.aggregate(settings)
end

--- Aggregates a decoded settings table into flat lists for each concern.
--- @param settings Settings
--- @return ParsedConfig
M.aggregate = function(settings)
  --- @type string[]
  local lsp_list = {}

  --- @type string[]
  local ft_list = {}

  --- @type table<string, string[]>
  local formatters_map = {}

  --- @type string[]
  local ts_list = {}

  for _, language in pairs(settings.languages) do
    if language.treesitters then
      for _, ts in pairs(language.treesitters) do
        ts_list[#ts_list + 1] = ts
      end
    end
    if language.lsp then
      for _, lsp in pairs(language.lsp) do
        lsp_list[#lsp_list + 1] = lsp
      end
    end
    if language.file_types then
      for _, ft in pairs(language.file_types) do
        ft_list[#ft_list + 1] = ft
        formatters_map[ft] = language.formatters
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
