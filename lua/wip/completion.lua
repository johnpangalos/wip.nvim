--- *wip.completion* Completion setup
---
--- Configures LSP-based auto-completion using Neovim 0.12+'s built-in
--- `autocomplete` option.
---
--- The `completeopt` flags tune the experience:
--- - `menuone`  always show the popup, even for a single match
--- - `noselect` never auto-select an item, so typing is never altered
--- - `fuzzy`    match partial / out-of-order input
--- - `popup`    show documentation and signatures next to the menu
---
--- Per LSP client, completion is enabled with `autotrigger` so the menu
--- also opens on server-defined trigger characters (e.g. `.`).

local M = {}

--- Sets up LSP-based auto-completion using Neovim 0.12's autocomplete option.
---@private
M.setup = function()
  vim.o.completeopt = "menuone,noselect,fuzzy,popup"
  vim.o.autocomplete = true

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
