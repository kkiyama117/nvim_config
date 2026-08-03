export function targetTriple(): string {
  const { os, arch } = Deno.build;
  if (os === "linux") {
    if (arch === "x86_64") return "x86_64-unknown-linux-gnu";
    if (arch === "aarch64") return "aarch64-unknown-linux-gnu";
  }
  if (os === "darwin") {
    if (arch === "x86_64") return "x86_64-apple-darwin";
    if (arch === "aarch64") return "aarch64-apple-darwin";
  }
  if (os === "windows" && arch === "x86_64") {
    return "x86_64-pc-windows-msvc";
  }
  throw new Error(`Unsupported platform: ${os}/${arch}`);
}

export function archiveExtension(): "tar.gz" | "zip" {
  return Deno.build.os === "windows" ? "zip" : "tar.gz";
}
