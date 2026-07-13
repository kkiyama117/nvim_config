import { buildModel, GenExitError } from "./deps_as_json.ts";
import { renderLua } from "./render_lua.ts";
import { renderReadmeBlock } from "./render_readme.ts";
import { renderReference } from "./render_reference.ts";
import { replaceBetween } from "./sentinels.ts";

// Output files of the AUTO-GENERATED deps list
const LUA_OUT = "lua/dpp_min_deps.lua";
const README_OUT = "deps/README.md";
const REFERENCE_OUT = "docs/references/deps-list.md";
const DOCS_INDEX = "docs/README.md";

// Marker of the rendering start and end
const START_MARKER = /^-- AUTO GENERATED PLUGIN LIST$/;
const END_MARKER = /^-- AUTO GENERATED PLUGIN LIST END$/;

const DOCS_INDEX_LINE =
  "- [references/deps-list.md](references/deps-list.md) — Auto-generated plugin list across all `deps/*.toml`.";
const DOCS_INDEX_SECTION = `
## Generated references

${DOCS_INDEX_LINE}
`;

async function writeText(path: string, content: string): Promise<void> {
  try {
    await Deno.writeTextFile(path, content);
  } catch (e) {
    throw new GenExitError(
      5,
      `I/O error writing ${path}: ${e instanceof Error ? e.message : String(e)}`,
    );
  }
}

function ensureDocsIndexLine(): void {
  let text: string;
  try {
    text = Deno.readTextFileSync(DOCS_INDEX);
  } catch (e) {
    throw new GenExitError(
      5,
      `I/O error reading ${DOCS_INDEX}: ${e instanceof Error ? e.message : String(e)}`,
    );
  }
  if (text.includes("references/deps-list.md")) return;
  const trimmed = text.replace(/\n+$/, "\n");
  try {
    Deno.writeTextFileSync(DOCS_INDEX, trimmed + DOCS_INDEX_SECTION);
  } catch (e) {
    throw new GenExitError(
      5,
      `I/O error writing ${DOCS_INDEX}: ${e instanceof Error ? e.message : String(e)}`,
    );
  }
  console.log(`[gen_deps] added index line to ${DOCS_INDEX}`);
}

async function main(): Promise<void> {
  const model = await buildModel();

  await writeText(LUA_OUT, renderLua(model));
  console.log(`[gen_deps] wrote ${LUA_OUT}`);

  const readmeBlock = renderReadmeBlock(model);
  try {
    replaceBetween(
      README_OUT,
      START_MARKER,
      END_MARKER,
      readmeBlock,
      { preserveMarkers: true },
    );
  } catch (e) {
    if (e instanceof GenExitError) throw e;
    throw new GenExitError(
      5,
      `I/O error updating ${README_OUT}: ${e instanceof Error ? e.message : String(e)}`,
    );
  }
  console.log(`[gen_deps] updated sentinel block in ${README_OUT}`);

  await writeText(REFERENCE_OUT, renderReference(model));
  console.log(`[gen_deps] wrote ${REFERENCE_OUT}`);

  ensureDocsIndexLine();
}

if (import.meta.main) {
  try {
    await main();
  } catch (e) {
    if (e instanceof GenExitError) {
      console.error(`[gen_deps] error (exit ${e.code}): ${e.message}`);
      Deno.exit(e.code);
    }
    console.error(
      `[gen_deps] unexpected error: ${e instanceof Error ? e.message : String(e)}`,
    );
    Deno.exit(1);
  }
}
