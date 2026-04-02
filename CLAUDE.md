# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

wip.nvim is a Neovim plugin that simplifies language-specific development environment setup through a single JSON configuration file (`~/.config/nvim/wip.config.json`). It wraps three Neovim plugin ecosystems: nvim-treesitter (syntax), nvim-lspconfig (LSP), and conform.nvim (formatting).

## Architecture

**Entry point**: `plugin/wip.lua` → `require("wip")` → `lua/wip/init.lua`

The core is `lua/wip/init.lua` (~150 LOC) which exposes `setup()`:
1. Reads and parses `~/.config/nvim/wip.config.json`
2. For each configured language: installs treesitter parsers, downloads/enables LSP configs from nvim-lspconfig GitHub, registers formatters with conform.nvim
3. Sets up FileType and LspAttach autocmds

**Schema generation**: `scripts/generate-schema.ts` fetches valid enum values (file types, LSPs, treesitters, formatters) from upstream GitHub repos (neovim, nvim-treesitter, conform.nvim, nvim-lspconfig) and writes `schema.json`. Requires `GHA_TOKEN` in `.env`.

## Commands

### Schema generation
```bash
cd scripts && pnpm install && pnpm tsx generate-schema.ts
```

### Tests
```bash
nvim --headless -l tests/run.lua
```

## Conventions

- Use pnpm, not npm (for the scripts/ directory)
- Semantic/conventional commits (`fix:`, `feat:`, `chore:`, `docs:`, `test:`, `refactor:`) with a title and description
- Lua targets LuaJIT 5.1 (see `.luarc.json`)
- 2-space indentation (see `.editorconfig`)
