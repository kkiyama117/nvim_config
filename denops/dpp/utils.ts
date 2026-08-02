import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";

import { ensure, is } from "@core/unknownutil";

import type {
  Ext as TomlExt,
  Params as TomlParams,
  Toml,
} from "@shougo/dpp-ext-toml";

// --------------------------------------------------------------------------
// Util functions
// --------------------------------------------------------------------------
const isStringArray = is.ArrayOf(is.String);

async function glob(denops: Denops, path: string): Promise<string[]> {
  return ensure(
    await denops.call("glob", path, 1, 1),
    isStringArray,
  );
}

export async function gatherGlobs(
  denops: Denops,
  globs: string[],
  basePath?: string,
): Promise<string[]> {
  const results = basePath === undefined
    ? await Promise.all(globs.map((pattern) => glob(denops, pattern)))
    : await Promise.all(
      globs.map((pattern) =>
        fn.globpath(denops, basePath, pattern, true, true)
      ),
    );
  return results.flat();
}

//export async function gatherTomls(
//  path: string,
//  noLazyTomlNames: string[],
//  args: ConfigArguments,
//): Promise<Toml[]> {
//  const tomls: Toml[] = [];
//  const [context, options] = await args.contextBuilder.get(args.denops);
//
//  for (const tomlFile of Deno.readDirSync(path)) {
//    if (typeof tomlFile.name === "undefined") continue;
//    const isLazy = !noLazyTomlNames.includes(tomlFile.name);
//    tomls.push(
//      await args.dpp.extAction(
//        args.denops,
//        context,
//        options,
//        "load",
//        {
//          path: `${path}/${tomlFile.name}`,
//          options: {
//            lazy: isLazy,
//          },
//        },
//      ) as Toml,
//    );
//  }
//  return tomls;
//}
//

