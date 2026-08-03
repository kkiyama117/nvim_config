export interface BinSpec {
  /** Command name used in dpp `external_commands`. */
  name: string;
  /** GitHub repository in `owner/repo` form. */
  repo: string;
  defaultDest: (home: string) => string;
  assetName: (version: string, triple: string) => string;
  binaryName: () => string;
}

export interface InstallOptions {
  dest: string;
  force: boolean;
  version?: string;
}
