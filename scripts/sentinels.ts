import { GenExitError } from "./deps_as_json.ts";

export interface ReplaceBetweenOpts {
  preserveMarkers: true;
}

const SEP_LINE = /^-{5,}$/;

/**
 * Replace the content between two sentinel marker lines in a file.
 *
 * - `startMarker` / `endMarker` are tested against individual lines.
 * - The marker line itself is preserved, along with adjacent separator lines
 *   matching `/^-{5,}$/` (the `---` border lines used in `deps/README.md`).
 * - Exactly one blank line separates the marker block from the new content on
 *   each side (idempotency).
 * - Throws `GenExitError(3, ...)` if either marker is absent.
 */
export function replaceBetween(
  filePath: string,
  startMarker: RegExp,
  endMarker: RegExp,
  newContent: string,
  _opts: ReplaceBetweenOpts,
): void {
  const text = Deno.readTextFileSync(filePath);
  // Preserve the original file's trailing newline shape by splitting on "\n"
  // and re-joining with "\n". A trailing "\n" produces a trailing "" element
  // which we keep.
  const lines = text.split("\n");

  let si = -1;
  for (let i = 0; i < lines.length; i++) {
    if (startMarker.test(lines[i])) {
      si = i;
      break;
    }
  }
  if (si === -1) {
    throw new GenExitError(
      3,
      `start marker not found in ${filePath}: ${startMarker}`,
    );
  }

  let ei = -1;
  for (let i = si + 1; i < lines.length; i++) {
    if (endMarker.test(lines[i])) {
      ei = i;
      break;
    }
  }
  if (ei === -1) {
    throw new GenExitError(
      3,
      `end marker not found in ${filePath}: ${endMarker}`,
    );
  }

  // Expand preserved regions to include adjacent separator (`---`) lines so
  // the full 3-line marker block (`---` / `-- ...` / `---`) survives.
  let startBlockEnd = si;
  while (
    startBlockEnd < lines.length - 1 && SEP_LINE.test(lines[startBlockEnd + 1])
  ) {
    startBlockEnd++;
  }
  let endBlockStart = ei;
  while (endBlockStart > si + 1 && SEP_LINE.test(lines[endBlockStart - 1])) {
    endBlockStart--;
  }

  const before = lines.slice(0, startBlockEnd + 1);
  const after = lines.slice(endBlockStart);

  // Trim trailing/leading empty lines from newContent so we control blank
  // line placement ourselves.
  const contentLines = newContent.split("\n");
  while (contentLines.length > 0 && contentLines[0] === "") contentLines.shift();
  while (
    contentLines.length > 0 && contentLines[contentLines.length - 1] === ""
  ) {
    contentLines.pop();
  }

  const result = [...before, "", ...contentLines, "", ...after].join("\n");
  Deno.writeTextFileSync(filePath, result);
}
