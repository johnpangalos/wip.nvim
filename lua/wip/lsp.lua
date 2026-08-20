--- *wip.lsp* LSP setup
---
--- Downloads missing LSP configurations from the nvim-lspconfig
--- repository and enables LSP servers via `vim.lsp.enable()`.
---
--- # Config precedence ~
---
--- `vim.lsp.config[name]` resolves by deep-merging every `lsp/<name>.lua`
--- found on the 'runtimepath', in 'runtimepath' order, so the LAST file
--- wins. The config directory is FIRST on the 'runtimepath', which means a
--- plugin that ships its own `lsp/<name>.lua` -- nvim-lspconfig does, for
--- every server -- silently overrides the copy wip.nvim downloaded, together
--- with any edits made to it.
---
--- Calls to `vim.lsp.config()` are merged after the whole 'runtimepath'
--- chain, so wip.nvim re-applies the files in the config directory through
--- it. That makes `<config>/lsp/` authoritative, which is what downloading
--- into it assumes. Your own `vim.lsp.config()` calls still win as long as
--- they run after `require("wip").setup()`.

local M = {}

local NVIM_LSP_CONFIG_RAW_URL = "https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp/"

--- Reports a problem without interrupting the current callback.
---@private
---@param msg string
local function warn(msg)
  vim.schedule(function()
    vim.notify("wip.nvim: " .. msg, vim.log.levels.ERROR)
  end)
end

--- Re-applies a config from the config directory so it outranks the copies
--- that other plugins put on the 'runtimepath'. See |wip.lsp|.
---@private
---@param lsp string The name of the lsp to re-apply
---@param base_path string The base config directory
local function apply_local_config(lsp, base_path)
  local path = base_path .. "/lsp/" .. lsp .. ".lua"

  local ok, config = pcall(dofile, path)
  if not ok then
    warn("could not load " .. path .. ": " .. tostring(config))
    return
  end
  if type(config) ~= "table" then
    warn(path .. " did not return a table")
    return
  end

  vim.lsp.config(lsp, config)
end

--- Enables a single LSP server.
---
--- `vim.lsp.enable()` raises when a config cannot be resolved, so each server
--- is enabled in isolation: a broken or missing config must not stop the
--- remaining servers in the list from being enabled.
---@private
---@param lsp string The name of the lsp to enable
local function enable_lsp(lsp)
  local ok, err = pcall(vim.lsp.enable, lsp)
  if not ok then
    warn("could not enable " .. lsp .. ": " .. tostring(err))
  end
end

--- Downloads an LSP config from the nvim-lspconfig repository and saves it locally.
---@private
---@param lsp string The name of the lsp to download
---@param base_path string The base config directory
---@param callback fun()|nil
local function download_lsp_config(lsp, base_path, callback)
  local url = NVIM_LSP_CONFIG_RAW_URL .. lsp .. ".lua"
  vim.net.request(url, nil, function(err, res)
    if err then
      warn("could not download " .. lsp .. ": " .. tostring(err))
      return
    end

    local lsp_def_file = io.open(base_path .. "/lsp/" .. lsp .. ".lua", "w")
    if lsp_def_file == nil then
      warn("could not write config for " .. lsp .. " to " .. base_path .. "/lsp")
      return
    end
    lsp_def_file:write(res.body)
    lsp_def_file:close()

    if callback ~= nil then
      callback()
    end
  end)
end

--- Downloads missing LSP configs and enables all LSP servers.
---@private
---@param lsp_list string[] List of LSP server names
---@param base_path string The base config directory (e.g. ~/.config/nvim)
M.setup = function(lsp_list, base_path)
  if #lsp_list == 0 then
    return
  end

  -- Downloads run in a fast event context where `vim.fn` is unavailable, so
  -- make sure the destination exists before any request is fired.
  vim.fn.mkdir(base_path .. "/lsp", "p")

  -- Every file in the directory, not just the configured servers: the
  -- precedence problem applies to all of them. See |wip.lsp|.
  for entry, entry_type in vim.fs.dir(base_path .. "/lsp") do
    local name = entry:match("^(.*)%.lua$")
    if name and (entry_type == "file" or entry_type == "link") then
      apply_local_config(name, base_path)
    end
  end

  for _, lsp in ipairs(lsp_list) do
    local lsp_def_file = io.open(base_path .. "/lsp/" .. lsp .. ".lua", "r")
    if lsp_def_file == nil then
      download_lsp_config(lsp, base_path, function()
        vim.schedule(function()
          -- The file did not exist during the pass above, so apply it now.
          apply_local_config(lsp, base_path)
          enable_lsp(lsp)
        end)
      end)
    else
      lsp_def_file:close()
      enable_lsp(lsp)
    end
  end
end

return M
