local M = {}

--- @class Language
--- @field name string
--- @field lsp string[]
--- @field file_types string[]
--- @field formatters string[]
--- @field treesitters string[]

--- @class Settings
--- @field languages Language[]

local FILE_BASE = vim.env.HOME .. "/.config/nvim"
local SETTINGS_FILE_PATH = FILE_BASE .. "/wip.config.json"

M.setup = function()
  local parsed = require("wip.config").parse(SETTINGS_FILE_PATH)

  require("wip.lsp").setup(parsed.lsp_list, FILE_BASE)
  require("wip.treesitter").setup(parsed.ts_list, parsed.ft_list)
  require("wip.formatter").setup(parsed.formatters_map)
  require("wip.completion").setup()
end

return M
