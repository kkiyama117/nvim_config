import type { DepsModel, PluginEntry, SourceToml } from "./deps_as_json.ts";

function desc(p: PluginEntry): string {
  return p.description && p.description.length > 0
    ? p.description
    : "_(no description in toml)_";
}

function pluginTable(entries: PluginEntry[]): string {
  const lines = [
    "| repo | description |",
    "|------|-------------|",
  ];
  for (const p of entries) {
    lines.push(`| \`${p.repo}\` | ${desc(p)} |`);
  }
  return lines.join("\n");
}

const OTHER_TOMLS: { source: SourceToml; label: string }[] = [
  { source: "denops", label: "deps/denops.toml" },
  { source: "neovim", label: "deps/neovim.toml" },
  { source: "merge", label: "deps/merge.toml" },
];

export function renderReadmeBlock(model: DepsModel): string {
  const byRepo = new Map(model.plugins.map((p) => [p.repo, p]));

  const minEntries = model.minimum_deps
    .map((r) => byRepo.get(r))
    .filter((p): p is PluginEntry => p !== undefined);
  const normalEntries = model.normal_deps
    .map((r) => byRepo.get(r))
    .filter((p): p is PluginEntry => p !== undefined);

  const sections: string[] = [
    "## Minimum loaded",
    "",
    pluginTable(minEntries),
    "",
    "## Normal dpp deps (loaded before denops ready)",
    "",
    pluginTable(normalEntries),
    "",
    "## Other TOMLs",
    "",
  ];

  for (const { source, label } of OTHER_TOMLS) {
    const count = model.by_toml[source].length;
    const suffix = source === "denops"
      ? ` — see [docs/references/deps-list.md](../docs/references/deps-list.md) for the full table.`
      : "";
    sections.push(`- \`${label}\`: ${count} plugin${count === 1 ? "" : "s"}${suffix}`);
  }

  return sections.join("\n");
}
