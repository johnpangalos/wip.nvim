local M = {}

local NVIM_LSP_CONFIG_RAW_URL = "https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp/"

--- Downloads an LSP config from the nvim-lspconfig repository and saves it locally.
--- @param lsp string: The name of the lsp to download
--- @param base_path string: The base config directory
--- @param callback fun() | nil
local function download_lsp_config(lsp, base_path, callback)
  local url = NVIM_LSP_CONFIG_RAW_URL .. lsp .. ".lua"
  vim.net.request(url, nil, function(err, res)
    if err then
      vim.print("Could not download " .. lsp)
      vim.print(err)
      return
    end
    local lsp_def_file = assert(io.open(base_path .. "/lsp/" .. lsp .. ".lua", "w"))
    lsp_def_file:write(res.body)
    lsp_def_file:close()

    if callback ~= nil then
      callback()
    end
  end)
end

--- Downloads missing LSP configs and enables all LSP servers.
--- @param lsp_list string[]: list of LSP server names
--- @param base_path string: the base config directory (e.g. ~/.config/nvim)
M.setup = function(lsp_list, base_path)
  for _, lsp in pairs(lsp_list) do
    local lsp_def_file = io.open(base_path .. "/lsp/" .. lsp .. ".lua", "r")
    if lsp_def_file == nil then
      download_lsp_config(lsp, base_path, function()
        vim.schedule(function()
          vim.lsp.enable(lsp)
        end)
      end)
    else
      lsp_def_file:close()
      vim.lsp.enable(lsp)
    end
  end
end

return M
