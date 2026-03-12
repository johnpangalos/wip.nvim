local M = {}

--- Sets up LSP-based auto-completion with autotrigger.
M.setup = function()
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
