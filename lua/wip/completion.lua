--- *wip.completion* Completion setup
---
--- Configures LSP-based auto-completion using Neovim 0.12+'s built-in
--- `autocomplete` option.

local M = {}

--- Sets up LSP-based auto-completion using Neovim 0.12's autocomplete option.
M.setup = function()
  vim.o.completeopt = "menuone,noselect"
  vim.o.autocomplete = true

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client == nil then
        return
      end
      if client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, client.id, ev.buf, {})
      end
    end,
  })
end

return M
