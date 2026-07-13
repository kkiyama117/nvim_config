import { parse } from "@std/toml";

export type SourceToml = "dpp" | "denops" | "neovim" | "merge";

export interface PluginEntry {
  repo: string;
  description?: string;
  rtp?: string;
  if_expr?: string;
  on_ft?: string[] | string;
  on_event?: string[] | string;
  on_source?: string[] | string;
  depends?: string[] | string;
  external_commands?: string[] | string;
  hook_add?: string;
  hook_source?: string;
  lua_source?: string;
  extAttrs?: Record<string, unknown>;
  source_toml: SourceToml;
}

export interface DepsModel {
  plugins: PluginEntry[];
  by_toml: Record<SourceToml, PluginEntry[]>;
  minimum_deps: string[];
  normal_deps: string[];
}

export class GenExitError extends Error {
  constructor(
    public readonly code: number,
    message: string,
  ) {
    super(message);
    this.name = "GenExitError";
  }
}

export const MINIMUM_REPOS = new Set(["Shougo/dpp.vim", "Shougo/dpp-ext-lazy"]);

const TOML_FILES: { path: string; source: SourceToml }[] = [
  { path: "deps/dpp.toml", source: "dpp" },
  { path: "deps/denops.toml", source: "denops" },
  { path: "deps/neovim.toml", source: "neovim" },
  { path: "deps/merge.toml", source: "merge" },
];

function asString(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function asStringOrArray(value: unknown): string[] | string | undefined {
  if (typeof value === "string") return value;
  if (Array.isArray(value) && value.every((v) => typeof v === "string")) {
    return value as string[];
  }
  return undefined;
}

function toPluginEntry(
  raw: Record<string, unknown>,
  source: SourceToml,
): PluginEntry {
  const repo = raw["repo"];
  if (typeof repo !== "string") {
    throw new GenExitError(
      2,
      `plugin entry missing string "repo" field in ${source}.toml: ${JSON.stringify(raw)}`,
    );
  }
  const extAttrs = raw["extAttrs"];
  return {
    repo,
    description: asString(raw["description"]),
    rtp: asString(raw["rtp"]),
    if_expr: asString(raw["if"]),
    on_ft: asStringOrArray(raw["on_ft"]),
    on_event: asStringOrArray(raw["on_event"]),
    on_source: asStringOrArray(raw["on_source"]),
    depends: asStringOrArray(raw["depends"]),
    external_commands: asStringOrArray(raw["external_commands"]),
    hook_add: asString(raw["hook_add"]),
    hook_source: asString(raw["hook_source"]),
    lua_source: asString(raw["lua_source"]),
    extAttrs:
      extAttrs !== null && typeof extAttrs === "object" && !Array.isArray(extAttrs)
        ? (extAttrs as Record<string, unknown>)
        : undefined,
    source_toml: source,
  };
}

function classify(model: DepsModel): void {
  const dppEntries = model.by_toml.dpp;
  model.minimum_deps = dppEntries
    .filter((p) => MINIMUM_REPOS.has(p.repo))
    .map((p) => p.repo);
  model.normal_deps = dppEntries
    .filter((p) => !MINIMUM_REPOS.has(p.repo))
    .map((p) => p.repo);
  const denopsVim = model.by_toml.denops.find(
    (p) => p.repo === "vim-denops/denops.vim",
  );
  if (denopsVim) model.normal_deps.push(denopsVim.repo);

  // Q1: MINIMUM_REPOS must be fully present in dpp.toml (exit 4).
  if (model.minimum_deps.length !== MINIMUM_REPOS.size) {
    throw new GenExitError(
      4,
      `dpp.toml is missing one of MINIMUM_REPOS: ${[...MINIMUM_REPOS].join(", ")}`,
    );
  }

  // Q7: no repo classified twice (exit 6). The complementary predicate
  // (filter MINIMUM_REPOS.has / filter !has) already guarantees full
  // coverage; this only guards against denops.vim being added to dpp.toml
  // or a duplicate [[plugins]] entry.
  const all = [...model.minimum_deps, ...model.normal_deps];
  if (new Set(all).size !== all.length) {
    throw new GenExitError(
      6,
      `repo classified twice in minimum_deps/normal_deps: ${all.join(", ")}`,
    );
  }
}

export async function buildModel(): Promise<DepsModel> {
  const plugins: PluginEntry[] = [];
  const by_toml: Record<SourceToml, PluginEntry[]> = {
    dpp: [],
    denops: [],
    neovim: [],
    merge: [],
  };

  for (const { path, source } of TOML_FILES) {
    let text: string;
    try {
      text = await Deno.readTextFile(path);
    } catch (e) {
      throw new GenExitError(
        2,
        `failed to read ${path}: ${e instanceof Error ? e.message : String(e)}`,
      );
    }
    let parsed: Record<string, unknown>;
    try {
      parsed = parse(text) as Record<string, unknown>;
    } catch (e) {
      throw new GenExitError(
        2,
        `TOML parse error in ${path}: ${e instanceof Error ? e.message : String(e)}`,
      );
    }
    const rawPlugins = parsed["plugins"];
    if (rawPlugins === undefined) continue;
    if (!Array.isArray(rawPlugins)) {
      throw new GenExitError(
        2,
        `expected [[plugins]] array in ${path}, got ${typeof rawPlugins}`,
      );
    }
    for (const raw of rawPlugins) {
      if (typeof raw !== "object" || raw === null) {
        throw new GenExitError(2, `non-object [[plugins]] entry in ${path}`);
      }
      const entry = toPluginEntry(raw as Record<string, unknown>, source);
      plugins.push(entry);
      by_toml[source].push(entry);
    }
  }

  const model: DepsModel = {
    plugins,
    by_toml,
    minimum_deps: [],
    normal_deps: [],
  };
  classify(model);
  return model;
}
