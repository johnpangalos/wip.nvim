local formatter = require("wip.formatter")

describe("wip.formatter", function()
  it("maps formatters to file types via conform", function()
    -- Stub conform.nvim
    package.loaded["conform"] = { formatters_by_ft = {} }

    local formatters_map = {
      typescript = { "prettier" },
      go = { "gofmt" },
    }

    formatter.setup(formatters_map)

    local conform = require("conform")
    assert_eq(conform.formatters_by_ft["typescript"], { "prettier" })
    assert_eq(conform.formatters_by_ft["go"], { "gofmt" })

    -- Cleanup
    package.loaded["conform"] = nil
  end)

  it("handles empty formatters map", function()
    package.loaded["conform"] = { formatters_by_ft = {} }

    formatter.setup({})

    local conform = require("conform")
    assert_eq(next(conform.formatters_by_ft), nil)

    -- Cleanup
    package.loaded["conform"] = nil
  end)
end)
