local config = require("wip.config")

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local fixtures = root .. "/tests/fixtures"

describe("wip.config", function()
  describe("parse", function()
    it("parses a full config with all fields", function()
      local parsed = config.parse(fixtures .. "/valid_config.json")

      assert_eq(#parsed.lsp_list, 3)
      assert_eq(parsed.lsp_list[1], "tsgo")
      assert_eq(parsed.lsp_list[2], "eslint")
      assert_eq(parsed.lsp_list[3], "gopls")

      assert_eq(#parsed.ts_list, 4)
      assert_eq(parsed.ts_list[1], "typescript")
      assert_eq(parsed.ts_list[2], "tsx")
      assert_eq(parsed.ts_list[3], "go")
      assert_eq(parsed.ts_list[4], "markdown")

      assert_eq(#parsed.ft_list, 4)
      assert_eq(parsed.ft_list[1], "typescript")
      assert_eq(parsed.ft_list[2], "typescriptreact")
      assert_eq(parsed.ft_list[3], "go")
      assert_eq(parsed.ft_list[4], "markdown")
    end)

    it("maps formatters to file types correctly", function()
      local parsed = config.parse(fixtures .. "/valid_config.json")

      assert_eq(parsed.formatters_map["typescript"], { "prettier" })
      assert_eq(parsed.formatters_map["typescriptreact"], { "prettier" })
      assert_eq(parsed.formatters_map["go"], { "gofmt" })
      assert_eq(parsed.formatters_map["markdown"], nil)
    end)

    it("handles minimal config with only required fields", function()
      local parsed = config.parse(fixtures .. "/minimal_config.json")

      assert_len(parsed.lsp_list, 0)
      assert_len(parsed.ts_list, 0)
      assert_len(parsed.ft_list, 1)
      assert_eq(parsed.ft_list[1], "gitcommit")
    end)

    it("handles empty languages array", function()
      local parsed = config.parse(fixtures .. "/empty_config.json")

      assert_len(parsed.lsp_list, 0)
      assert_len(parsed.ft_list, 0)
      assert_len(parsed.ts_list, 0)
    end)
  end)

  describe("aggregate", function()
    it("aggregates multiple languages into flat lists", function()
      local settings = {
        languages = {
          { name = "a", lsp = { "lsp_a" }, file_types = { "ft_a" }, treesitters = { "ts_a" } },
          { name = "b", lsp = { "lsp_b" }, file_types = { "ft_b" }, treesitters = { "ts_b" } },
        },
      }

      local parsed = config.aggregate(settings)

      assert_len(parsed.lsp_list, 2)
      assert_len(parsed.ft_list, 2)
      assert_len(parsed.ts_list, 2)
    end)

    it("skips nil optional fields without error", function()
      local settings = {
        languages = {
          { name = "plain", file_types = { "text" } },
        },
      }

      local parsed = config.aggregate(settings)

      assert_len(parsed.lsp_list, 0)
      assert_len(parsed.ts_list, 0)
      assert_len(parsed.ft_list, 1)
    end)
  end)
end)
