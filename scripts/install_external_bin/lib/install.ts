import { ensureDir } from "@std/fs";
import { dirname } from "@std/path";

import type { BinSpec, InstallOptions } from "../types.ts";
import { extractBinary } from "./archive.ts";
import { downloadAsset, fetchRelease, findAsset } from "./github_release.ts";
import { targetTriple } from "./platform.ts";

export async function installBin(
  spec: BinSpec,
  options: InstallOptions,
): Promise<void> {
  if (!options.force) {
    try {
      const stat = await Deno.stat(options.dest);
      if (stat.isFile) {
        console.log(`Already installed: ${options.dest}`);
        console.log("Use --force to reinstall.");
        return;
      }
    } catch (error) {
      if (!(error instanceof Deno.errors.NotFound)) {
        throw error;
      }
    }
  }

  const triple = targetTriple();
  const release = await fetchRelease(spec.repo, options.version);
  const assetName = spec.assetName(release.tag_name, triple);
  const asset = findAsset(release, assetName);

  console.log(`Installing ${spec.name} ${release.tag_name} (${asset.name})`);
  console.log(`Destination: ${options.dest}`);

  const archive = await downloadAsset(asset.browser_download_url);
  const binary = await extractBinary(archive, asset.name, spec.binaryName());
  await writeBinary(options.dest, binary);

  console.log("Done.");
}

async function writeBinary(dest: string, binary: Uint8Array): Promise<void> {
  await ensureDir(dirname(dest));
  await Deno.writeFile(dest, binary);
  if (Deno.build.os !== "windows") {
    await Deno.chmod(dest, 0o755);
  }
}
