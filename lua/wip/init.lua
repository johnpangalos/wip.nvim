--- *wip.txt*    wip.nvim
---
--- Simplifies language-specific development environment setup through a
--- single JSON config file (~/.config/nvim/wip.config.json). Wraps
--- nvim-treesitter, nvim-lspconfig, and conform.nvim.
---
--- # Setup ~
---
--- Add to your Neovim config:
--- >lua
---   require("wip").setup()
--- <
---
--- # Configuration ~
---
--- Create `~/.config/nvim/wip.config.json`. See |wip.config| for the
--- schema and the `examples/` directory for a complete example.

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
