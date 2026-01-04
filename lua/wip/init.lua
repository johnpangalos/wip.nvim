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
local SETTINGS_FILE_PATH = FILE_BASE .. "/languages.json"
local NVIM_LSP_CONFIG_RAW_URL = "https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp/"

--- Handles the response from downloading the lsp config. Saves the content to
--- the correct file. Shows the user an error if there is one
--- @param lsp string: The name of the lsp to download
--- @param callback fun() | nil
local function download_lsp_config(lsp, callback)
  local url = NVIM_LSP_CONFIG_RAW_URL .. lsp .. ".lua"
  vim.net.request(url, nil, function(err, res)
    if err then
      vim.print("Could not download" .. lsp)
      vim.print(err)
      return
    end
    local lsp_def_file = assert(io.open(FILE_BASE .. "/lsp/" .. lsp .. ".lua", "w"))
    lsp_def_file:write(res.body)
    lsp_def_file:close()

    if callback ~= nil then
      callback()
    end
  end)
end

--- @param lsp string: the lsp to enable
local function enable_lang(lsp)
  vim.lsp.enable(lsp)
end

M.setup = function()
  local settings_file = assert(io.open(SETTINGS_FILE_PATH))
  local settings_raw = settings_file:read("*a")
  settings_file:close()

  --- @type Settings
  local settings = vim.json.decode(settings_raw)

  --- @type  string[]
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
        local next = #ts_list and #ts_list + 1 or 1
        ts_list[next] = ts
      end
    end
    if language.lsp then
      for _, lsp in pairs(language.lsp) do
        local next = #lsp_list and #lsp_list + 1 or 1
        lsp_list[next] = lsp
      end
    end
    if language.file_types then
      for _, ft in pairs(language.file_types) do
        local next = #ft_list and #ft_list + 1 or 1
        ft_list[next] = ft
        formatters_map[ft] = language.formatters
      end
    end
  end

  for _, lsp in pairs(lsp_list) do
    local lsp_def_file = io.open(FILE_BASE .. "/lsp/" .. lsp .. ".lua", "r")
    if lsp_def_file == nil then
      download_lsp_config(lsp, function()
        vim.schedule(function()
          enable_lang(lsp)
        end)
      end)
    else
      lsp_def_file:close()
      enable_lang(lsp)
    end
  end

  local ts = require("nvim-treesitter")
  --- @type table<string, boolean>
  local ts_map = {}
  for _, p in ipairs(ts.get_installed("parsers")) do
    ts_map[p] = true
  end

  for _, p in ipairs(ts.get_installed("parsers")) do
    ts_map[p] = true
  end

  for _, t in pairs(ts_list) do
    if ts_map[ts] == nil then
      -- turn treesitter install into a syncronous call with a max timeout of
      -- 5 minutes.
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

  for ft, formatters in pairs(formatters_map) do
    local conform = require("conform")
    conform.formatters_by_ft[ft] = formatters
  end

  -- auto completion
  vim.o.completeopt = "menuone,noselect"

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client == nil then
        return
      end
      if client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      end
    end,
  })
end

return M
