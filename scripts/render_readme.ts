import type { DepsModel, PluginEntry } from "./deps_as_json.ts";
import {
  DENOPS_SOURCE,
  DPP_SOURCE,
  orderedSources,
  sourceLabel,
} from "./deps_as_json.ts";

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

  for (const source of orderedSources(model)) {
    if (source === DPP_SOURCE) continue;
    const count = model.by_toml.get(source)?.length ?? 0;
    const suffix = source === DENOPS_SOURCE
      ? ` — see [docs/references/deps-list.md](../docs/references/deps-list.md) for the full table.`
      : "";
    sections.push(`- \`${sourceLabel(source)}\`: ${count} plugin${count === 1 ? "" : "s"}${suffix}`);
  }

  return sections.join("\n");
}
