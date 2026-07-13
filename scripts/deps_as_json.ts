import { parse } from "@std/toml";

export type SourceToml = string;

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
  by_toml: Map<string, PluginEntry[]>;
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

export const DPP_SOURCE = "dpp";
export const DENOPS_SOURCE = "denops";

const DEPS_DIR = "deps";
const TOML_EXT = ".toml";

export function sourceLabel(source: string): string {
  return `${DEPS_DIR}/${source}${TOML_EXT}`;
}

async function* walkToml(dir: string): AsyncGenerator<string> {
  try {
    for await (const entry of Deno.readDir(dir)) {
      const full = `${dir}/${entry.name}`;
      if (entry.isDirectory) {
        yield* walkToml(full);
      } else if (entry.isFile && entry.name.endsWith(TOML_EXT)) {
        yield full;
      }
    }
  } catch (e) {
    throw new GenExitError(
      2,
      `failed to read directory ${dir}: ${e instanceof Error ? e.message : String(e)}`,
    );
  }
}

async function discoverTomlFiles(): Promise<{ path: string; source: string }[]> {
  const paths: string[] = [];
  for await (const p of walkToml(DEPS_DIR)) paths.push(p);
  paths.sort();
  if (paths.length === 0) {
    throw new GenExitError(2, `no ${TOML_EXT} files found under ${DEPS_DIR}/`);
  }
  const prefix = `${DEPS_DIR}/`;
  return paths.map((p) => ({
    path: p,
    source: p.slice(prefix.length, -TOML_EXT.length),
  }));
}

export function orderedSources(model: DepsModel): string[] {
  const sources = [...model.by_toml.keys()];
  const withoutDpp = sources.filter((s) => s !== DPP_SOURCE).sort();
  return sources.includes(DPP_SOURCE) ? [DPP_SOURCE, ...withoutDpp] : withoutDpp;
}

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
      `plugin entry missing string "repo" field in ${sourceLabel(source)}: ${JSON.stringify(raw)}`,
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
  const dppEntries = model.by_toml.get(DPP_SOURCE);
  if (dppEntries === undefined) {
    throw new GenExitError(
      2,
      `${sourceLabel(DPP_SOURCE)} not found under ${DEPS_DIR}/; required for minimum_deps classification`,
    );
  }
  model.minimum_deps = dppEntries
    .filter((p) => MINIMUM_REPOS.has(p.repo))
    .map((p) => p.repo);
  model.normal_deps = dppEntries
    .filter((p) => !MINIMUM_REPOS.has(p.repo))
    .map((p) => p.repo);
  const denopsVim = model.by_toml.get(DENOPS_SOURCE)?.find(
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
  const files = await discoverTomlFiles();
  const plugins: PluginEntry[] = [];
  const by_toml = new Map<string, PluginEntry[]>();
  for (const { source } of files) by_toml.set(source, []);

  for (const { path, source } of files) {
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
      by_toml.get(source)!.push(entry);
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
