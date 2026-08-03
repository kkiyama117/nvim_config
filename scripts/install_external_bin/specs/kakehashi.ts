import { join } from "@std/path";

import type { BinSpec } from "../types.ts";
import { archiveExtension } from "../lib/platform.ts";

export const kakehashi: BinSpec = {
  name: "kakehashi",
  repo: "atusy/kakehashi",
  defaultDest: (home) => join(home, ".local", "bin", "kakehashi"),
  assetName: (version, triple) =>
    `kakehashi-${version}-${triple}.${archiveExtension()}`,
  binaryName: () => Deno.build.os === "windows" ? "kakehashi.exe" : "kakehashi",
};
