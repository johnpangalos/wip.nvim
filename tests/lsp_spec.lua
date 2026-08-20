local lsp = require("wip.lsp")

describe("wip.lsp", function()
  it("enables LSP servers that already have config files", function()
    local enabled = {}

    -- Stub vim.lsp.enable to track calls
    local original_enable = vim.lsp.enable
    vim.lsp.enable = function(name)
      table.insert(enabled, name)
    end

    -- Create a temp directory with a fake lsp config
    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp .. "/lsp", "p")
    local f = assert(io.open(tmp .. "/lsp/fake_lsp.lua", "w"))
    f:write("return {}")
    f:close()

    lsp.setup({ "fake_lsp" }, tmp)

    assert_len(enabled, 1)
    assert_eq(enabled[1], "fake_lsp")

    -- Cleanup
    vim.lsp.enable = original_enable
    vim.fn.delete(tmp, "rf")
  end)

  it("does not enable LSP servers that have no config file yet", function()
    local enabled = {}

    local original_enable = vim.lsp.enable
    vim.lsp.enable = function(name)
      table.insert(enabled, name)
    end

    -- Stub vim.net.request to avoid real downloads
    local original_request = vim.net.request
    vim.net.request = function(_, _, _) end

    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp .. "/lsp", "p")

    -- No config file exists, so it should try to download, not enable directly
    lsp.setup({ "missing_lsp" }, tmp)

    assert_len(enabled, 0)

    -- Cleanup
    vim.lsp.enable = original_enable
    vim.net.request = original_request
    vim.fn.delete(tmp, "rf")
  end)

  it("enables every LSP server in the list", function()
    local enabled = {}

    local original_enable = vim.lsp.enable
    vim.lsp.enable = function(name)
      table.insert(enabled, name)
    end

    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp .. "/lsp", "p")
    for _, name in ipairs({ "one", "two", "three" }) do
      local f = assert(io.open(tmp .. "/lsp/" .. name .. ".lua", "w"))
      f:write("return {}")
      f:close()
    end

    lsp.setup({ "one", "two", "three" }, tmp)

    assert_eq(enabled, { "one", "two", "three" })

    vim.lsp.enable = original_enable
    vim.fn.delete(tmp, "rf")
  end)

  it("keeps enabling the rest of the list when one server fails", function()
    local enabled = {}

    local original_enable = vim.lsp.enable
    vim.lsp.enable = function(name)
      if name == "broken" then
        error("no config found for broken")
      end
      table.insert(enabled, name)
    end

    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp .. "/lsp", "p")
    for _, name in ipairs({ "one", "broken", "three" }) do
      local f = assert(io.open(tmp .. "/lsp/" .. name .. ".lua", "w"))
      f:write("return {}")
      f:close()
    end

    lsp.setup({ "one", "broken", "three" }, tmp)

    assert_eq(enabled, { "one", "three" })

    vim.lsp.enable = original_enable
    vim.fn.delete(tmp, "rf")
  end)

  it("creates the lsp directory before downloading configs", function()
    local original_request = vim.net.request
    vim.net.request = function(_, _, _) end

    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")

    lsp.setup({ "missing_lsp" }, tmp)

    assert_eq(vim.fn.isdirectory(tmp .. "/lsp"), 1, "expected " .. tmp .. "/lsp to be created")

    vim.net.request = original_request
    vim.fn.delete(tmp, "rf")
  end)

  it("does nothing when the lsp list is empty", function()
    local enabled = {}

    local original_enable = vim.lsp.enable
    vim.lsp.enable = function(name)
      table.insert(enabled, name)
    end

    lsp.setup({}, "/nonexistent/path")

    assert_len(enabled, 0)

    vim.lsp.enable = original_enable
  end)
end)
