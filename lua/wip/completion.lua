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
        -- `autotrigger` is intentionally omitted: firing LSP completion on a
        -- trigger character (e.g. `.`) currently deletes that character on
        -- accept (neovim/neovim#35470, #25177). `vim.o.autocomplete` already
        -- opens the menu as you type, so we don't lose much.
        vim.lsp.completion.enable(true, client.id, ev.buf, {})
      end
    end,
  })
end

return M
