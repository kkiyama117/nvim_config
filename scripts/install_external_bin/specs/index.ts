import type { BinSpec } from "../types.ts";
import { kakehashi } from "./kakehashi.ts";

const specs: Record<string, BinSpec> = {
  [kakehashi.name]: kakehashi,
};

export function listSpecs(): BinSpec[] {
  return Object.values(specs);
}

export function getSpec(name: string): BinSpec {
  const spec = specs[name];
  if (!spec) {
    const available = Object.keys(specs).join(", ");
    throw new Error(`Unknown binary: ${name}\nAvailable: ${available}`);
  }
  return spec;
}
