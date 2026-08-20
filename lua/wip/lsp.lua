--- *wip.lsp* LSP setup
---
--- Downloads missing LSP configurations from the nvim-lspconfig
--- repository and enables LSP servers via `vim.lsp.enable()`.

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

  for _, lsp in ipairs(lsp_list) do
    local lsp_def_file = io.open(base_path .. "/lsp/" .. lsp .. ".lua", "r")
    if lsp_def_file == nil then
      download_lsp_config(lsp, base_path, function()
        vim.schedule(function()
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
