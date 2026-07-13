import { buildModel, GenExitError } from "./deps_as_json.ts";
import { renderLua } from "./render_lua.ts";

const LUA_OUT = "lua/dpp_min_deps.lua";

async function main(): Promise<void> {
  const model = await buildModel();

  const lua = renderLua(model);
  try {
    await Deno.writeTextFile(LUA_OUT, lua);
  } catch (e) {
    throw new GenExitError(
      5,
      `I/O error writing ${LUA_OUT}: ${e instanceof Error ? e.message : String(e)}`,
    );
  }

  console.log(`[gen_deps] wrote ${LUA_OUT}`);
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
