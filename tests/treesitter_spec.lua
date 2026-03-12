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
end)
