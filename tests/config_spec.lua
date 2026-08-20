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

    it("keeps every language sharing a file type instead of the last one", function()
      local parsed = config.parse(fixtures .. "/overlapping_config.json")

      -- Formatters from both languages that claim typescriptreact are kept.
      assert_eq(parsed.formatters_map["typescriptreact"], { "prettier", "rustywind" })
      assert_eq(parsed.formatters_map["typescript"], { "prettier" })
      assert_eq(parsed.formatters_map["css"], { "rustywind" })
    end)

    it("does not let a language without formatters clear an earlier one", function()
      local parsed = config.parse(fixtures .. "/overlapping_config.json")

      -- "typescript-extras" claims the typescript file type but sets no
      -- formatters, which must not wipe the mapping set by "typescript".
      assert_eq(parsed.formatters_map["typescript"], { "prettier" })
    end)

    it("deduplicates lsp, treesitter and file type entries", function()
      local parsed = config.parse(fixtures .. "/overlapping_config.json")

      assert_eq(parsed.lsp_list, { "tsgo", "eslint", "tailwindcss" })
      assert_eq(parsed.ts_list, { "typescript", "tsx", "css" })
      assert_eq(parsed.ft_list, { "typescript", "typescriptreact", "css" })
    end)

    it("gives each file type its own formatter list", function()
      local parsed = config.parse(fixtures .. "/overlapping_config.json")

      table.insert(parsed.formatters_map["typescript"], "mutated")

      assert_eq(parsed.formatters_map["typescriptreact"], { "prettier", "rustywind" })
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

    it("merges formatters from every language claiming a file type", function()
      local settings = {
        languages = {
          { name = "a", file_types = { "shared" }, formatters = { "fmt_a" } },
          { name = "b", file_types = { "shared" }, formatters = { "fmt_b" } },
        },
      }

      local parsed = config.aggregate(settings)

      assert_eq(parsed.formatters_map["shared"], { "fmt_a", "fmt_b" })
      assert_len(parsed.ft_list, 1)
    end)

    it("keeps every lsp when languages share a file type", function()
      local settings = {
        languages = {
          { name = "a", lsp = { "lsp_a" }, file_types = { "shared" } },
          { name = "b", lsp = { "lsp_b", "lsp_c" }, file_types = { "shared" } },
        },
      }

      local parsed = config.aggregate(settings)

      assert_eq(parsed.lsp_list, { "lsp_a", "lsp_b", "lsp_c" })
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
