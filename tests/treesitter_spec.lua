local treesitter = require("wip.treesitter")

describe("wip.treesitter", function()
  it("creates FileType autocmds for each file type", function()
    -- Stub nvim-treesitter to avoid real parser operations
    package.loaded["nvim-treesitter"] = {
      get_installed = function()
        return {}
      end,
      install = function()
        return { wait = function() end }
      end,
    }

    local autocmds_before = #vim.api.nvim_get_autocmds({ event = "FileType" })

    treesitter.setup({ "lua" }, { "lua", "vim" })

    local autocmds_after = vim.api.nvim_get_autocmds({ event = "FileType" })
    local created = #autocmds_after - autocmds_before

    assert_eq(created, 2, "expected 2 new FileType autocmds, got " .. created)

    -- Cleanup
    package.loaded["nvim-treesitter"] = nil
  end)

  it("installs missing treesitter parsers", function()
    local installed = {}

    package.loaded["nvim-treesitter"] = {
      get_installed = function()
        return { "lua" } -- lua already installed
      end,
      install = function(parser)
        table.insert(installed, parser)
        return { wait = function() end }
      end,
    }

    treesitter.setup({ "lua", "go", "rust" }, {})

    -- lua is already installed, so only go and rust should be installed
    assert_len(installed, 2)
    assert_eq(installed[1], "go")
    assert_eq(installed[2], "rust")

    -- Cleanup
    package.loaded["nvim-treesitter"] = nil
  end)

  it("creates one FileType autocmd per file type even with duplicates", function()
    package.loaded["nvim-treesitter"] = {
      get_installed = function()
        return {}
      end,
      install = function()
        return { wait = function() end }
      end,
    }

    local before = #vim.api.nvim_get_autocmds({ event = "FileType" })

    treesitter.setup({}, { "ruby", "ruby", "eruby" })

    local created = #vim.api.nvim_get_autocmds({ event = "FileType" }) - before

    assert_eq(created, 2, "expected 2 new FileType autocmds, got " .. created)

    package.loaded["nvim-treesitter"] = nil
  end)

  it("keeps installing parsers after one fails", function()
    local installed = {}

    package.loaded["nvim-treesitter"] = {
      get_installed = function()
        return {}
      end,
      install = function(parser)
        if parser == "broken" then
          error("install failed")
        end
        table.insert(installed, parser)
        return { wait = function() end }
      end,
    }

    treesitter.setup({ "go", "broken", "rust" }, {})

    assert_eq(installed, { "go", "rust" })

    package.loaded["nvim-treesitter"] = nil
  end)
end)
