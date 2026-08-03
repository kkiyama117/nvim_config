import { join } from "@std/path";

export async function extractBinary(
  archive: Uint8Array,
  assetName: string,
  binaryName: string,
): Promise<Uint8Array> {
  const tmpDir = await Deno.makeTempDir({ prefix: "install-external-bin-" });
  try {
    const archivePath = join(tmpDir, assetName);
    await Deno.writeFile(archivePath, archive);

    const extract = new Deno.Command("tar", {
      args: ["xf", archivePath, "-C", tmpDir],
      stdout: "piped",
      stderr: "piped",
    });
    const { code, stderr } = await extract.output();
    if (code !== 0) {
      throw new Error(new TextDecoder().decode(stderr).trim() || "tar failed");
    }

    const binaryPath = join(tmpDir, binaryName);
    return await Deno.readFile(binaryPath);
  } finally {
    await Deno.remove(tmpDir, { recursive: true });
  }
}
