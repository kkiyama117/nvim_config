import { installBin } from "./lib/install.ts";
import { getSpec, listSpecs } from "./specs/index.ts";
import type { InstallOptions } from "./types.ts";

function homeDir(): string {
  return Deno.env.get("HOME") ?? "~";
}

function printHelp(): void {
  const names = listSpecs().map((spec) => spec.name).join(", ");
  console.log(`Install binaries listed in dpp external_commands.

Usage:
  deno task install-external-bin <name> [options]
  deno run -A install_external_bin/main.ts <name> [options]

Binaries:
  ${names}

Options:
  --dest <path>      Install path (default: ~/.local/bin/<name>)
  --version <tag>    Release tag (default: latest, e.g. v0.9.0)
  --force, -f        Reinstall even if the binary already exists
  --list             List available binaries
  --help, -h         Show this help
`);
}

function parseArgs(args: string[]): { name?: string; options: InstallOptions } {
  const options: InstallOptions = {
    dest: "",
    force: false,
  };
  let name: string | undefined;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--") {
      continue;
    }
    switch (arg) {
      case "--dest":
        options.dest = args[++i] ?? options.dest;
        break;
      case "--force":
      case "-f":
        options.force = true;
        break;
      case "--version":
        options.version = args[++i];
        break;
      case "--list":
        for (const spec of listSpecs()) {
          console.log(spec.name);
        }
        Deno.exit(0);
        break;
      case "--help":
      case "-h":
        printHelp();
        Deno.exit(0);
        break;
      default:
        if (arg.startsWith("-")) {
          throw new Error(`Unknown argument: ${arg}`);
        }
        if (name) {
          throw new Error(`Unexpected argument: ${arg}`);
        }
        name = arg;
    }
  }

  return { name, options };
}

async function main(): Promise<void> {
  const { name, options } = parseArgs(Deno.args);
  if (!name) {
    printHelp();
    Deno.exit(1);
  }

  const spec = getSpec(name);
  if (!options.dest) {
    options.dest = spec.defaultDest(homeDir());
  }

  await installBin(spec, options);
}

if (import.meta.main) {
  try {
    await main();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    Deno.exit(1);
  }
}
