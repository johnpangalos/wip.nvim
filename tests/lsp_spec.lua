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

  it("makes the local config outrank a plugin's copy on the runtimepath", function()
    local original_enable = vim.lsp.enable
    vim.lsp.enable = function(_) end

    local original_rtp = vim.o.runtimepath

    -- Mirror a real setup: the config dir comes first on the runtimepath and
    -- a plugin (nvim-lspconfig) ships its own copy of the same server later.
    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp .. "/config/lsp", "p")
    vim.fn.mkdir(tmp .. "/plugin/lsp", "p")

    local mine = assert(io.open(tmp .. "/config/lsp/wip_precedence.lua", "w"))
    mine:write('return { cmd = { "mine" }, filetypes = { "lua" } }')
    mine:close()

    local theirs = assert(io.open(tmp .. "/plugin/lsp/wip_precedence.lua", "w"))
    theirs:write('return { cmd = { "theirs" }, filetypes = { "lua" } }')
    theirs:close()

    vim.opt.rtp:prepend(tmp .. "/plugin")
    vim.opt.rtp:prepend(tmp .. "/config")

    -- Without the re-apply, the plugin copy wins despite coming second.
    assert_eq(vim.lsp.config["wip_precedence"].cmd, { "theirs" })

    lsp.setup({ "wip_precedence" }, tmp .. "/config")

    assert_eq(vim.lsp.config["wip_precedence"].cmd, { "mine" })

    vim.lsp.enable = original_enable
    vim.o.runtimepath = original_rtp
    vim.fn.delete(tmp, "rf")
  end)

  it("re-applies every config in the lsp directory, not just configured ones", function()
    local original_enable = vim.lsp.enable
    vim.lsp.enable = function(_) end

    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp .. "/lsp", "p")

    for _, name in ipairs({ "wip_listed", "wip_unlisted" }) do
      local f = assert(io.open(tmp .. "/lsp/" .. name .. ".lua", "w"))
      f:write('return { cmd = { "' .. name .. '" } }')
      f:close()
    end

    lsp.setup({ "wip_listed" }, tmp)

    assert_eq(vim.lsp.config["wip_listed"].cmd, { "wip_listed" })
    assert_eq(vim.lsp.config["wip_unlisted"].cmd, { "wip_unlisted" })

    vim.lsp.enable = original_enable
    vim.fn.delete(tmp, "rf")
  end)

  it("survives a config file that errors or returns no table", function()
    local enabled = {}

    local original_enable = vim.lsp.enable
    vim.lsp.enable = function(name)
      table.insert(enabled, name)
    end

    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp .. "/lsp", "p")

    local broken = assert(io.open(tmp .. "/lsp/wip_broken.lua", "w"))
    broken:write('error("boom")')
    broken:close()

    local not_a_table = assert(io.open(tmp .. "/lsp/wip_not_table.lua", "w"))
    not_a_table:write('return 42')
    not_a_table:close()

    local fine = assert(io.open(tmp .. "/lsp/wip_fine.lua", "w"))
    fine:write('return { cmd = { "fine" } }')
    fine:close()

    lsp.setup({ "wip_fine" }, tmp)

    assert_eq(enabled, { "wip_fine" })
    assert_eq(vim.lsp.config["wip_fine"].cmd, { "fine" })

    vim.lsp.enable = original_enable
    vim.fn.delete(tmp, "rf")
  end)
end)
