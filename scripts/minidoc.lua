local minidoc = require("mini.doc")
minidoc.setup({})
minidoc.generate(
  {
    "lua/wip/init.lua",
    "lua/wip/config.lua",
    "lua/wip/lsp.lua",
    "lua/wip/treesitter.lua",
    "lua/wip/formatter.lua",
    "lua/wip/completion.lua",
  },
  "doc/wip.txt"
)
