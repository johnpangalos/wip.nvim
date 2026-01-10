import { type } from "arktype";
import { writeFile } from "node:fs/promises";

type File = {
  name: string;
  path: string;
  sha: string;
  size: number;
  url: string;
  html_url: string;
  git_url: string;
  download_url: string;
  type: string;
};

const ftsPromise = fetch(
  "https://api.github.com/repos/neovim/neovim/contents/runtime/syntax/",
  {
    headers: {
      Accept: "application/vnd.github.object",
      Authorization: `Bearer ${process.env.GHA_TOKEN}`,
      "X-GitHub-Api-Version": "2022-11-28",
    },
  },
).then((res) => res.json()) as Promise<{ entries: File[] }>;

const tsPromise = fetch(
  "https://api.github.com/repos/nvim-treesitter/nvim-treesitter/contents/runtime/queries/",
  {
    headers: {
      Accept: "application/vnd.github.object",
      Authorization: `Bearer ${process.env.GHA_TOKEN}`,
      "X-GitHub-Api-Version": "2022-11-28",
    },
  },
).then((res) => res.json()) as Promise<{ entries: File[] }>;

const formattersPromise = fetch(
  "https://api.github.com/repos/stevearc/conform.nvim/contents/lua/conform/formatters/",
  {
    headers: {
      Accept: "application/vnd.github.object",
      Authorization: `Bearer ${process.env.GHA_TOKEN}`,
      "X-GitHub-Api-Version": "2022-11-28",
    },
  },
).then((res) => res.json()) as Promise<{ entries: File[] }>;

const lspsPromise = fetch(
  "https://api.github.com/repos/neovim/nvim-lspconfig/contents/lsp/",
  {
    headers: {
      Accept: "application/vnd.github.object",
      Authorization: `Bearer ${process.env.GHA_TOKEN}`,
      "X-GitHub-Api-Version": "2022-11-28",
    },
  },
).then((res) => res.json()) as Promise<{ entries: File[] }>;

const [ftsRaw, tsRaw, formattersRaw, lspsRaw] = await Promise.all([
  ftsPromise,
  tsPromise,
  formattersPromise,
  lspsPromise,
]);

const fts = ftsRaw.entries
  .filter((ft) => ft.name.includes(".vim"))
  .map((ft) => ft.name.replace(".vim", ""));

const tss = tsRaw.entries.map((ts) => ts.name);

const formatters = formattersRaw.entries
  .filter((ft) => ft.name.includes(".lua"))
  .map((ft) => ft.name.replace(".lua", ""));

const lsps = lspsRaw.entries
  .filter((ft) => ft.name.includes(".lua"))
  .map((ft) => ft.name.replace(".lua", ""));

const Language = type({
  name: "string",
  file_types: type.enumerated(...fts),
  "lsp?": type.enumerated(...lsps),
  "treesitters?": type.enumerated(...tss),
  "formatters?": type.enumerated(...formatters),
});

const Schema = type({
  "languages?": Language.array(),
});

await writeFile("schema.json", JSON.stringify(Schema.toJsonSchema(), null, 2));
