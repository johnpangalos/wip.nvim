local completion = require("wip.completion")

describe("wip.completion", function()
  it("sets completeopt", function()
    vim.o.completeopt = ""

    completion.setup()

    assert_eq(vim.o.completeopt, "menuone,noselect")
  end)

  it("creates an LspAttach autocmd", function()
    local autocmds_before = #vim.api.nvim_get_autocmds({ event = "LspAttach" })

    completion.setup()

    local autocmds_after = #vim.api.nvim_get_autocmds({ event = "LspAttach" })
    local created = autocmds_after - autocmds_before

    assert(created >= 1, "expected at least 1 new LspAttach autocmd")
  end)
end)
