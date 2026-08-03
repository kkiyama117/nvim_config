interface ReleaseAsset {
  name: string;
  browser_download_url: string;
}

interface Release {
  tag_name: string;
  assets: ReleaseAsset[];
}

function githubHeaders(): HeadersInit {
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "User-Agent": "nvim-config-install-external-bin",
  };
  const token = Deno.env.get("GITHUB_API_TOKEN");
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

export async function fetchRelease(
  repo: string,
  version?: string,
): Promise<Release> {
  const url = version
    ? `https://api.github.com/repos/${repo}/releases/tags/${version}`
    : `https://api.github.com/repos/${repo}/releases/latest`;
  const res = await fetch(url, { headers: githubHeaders() });
  if (!res.ok) {
    throw new Error(
      `Failed to fetch release${version ? ` ${version}` : ""}: ${res.status} ${res.statusText}`,
    );
  }
  return await res.json() as Release;
}

export function findAsset(
  release: Release,
  assetName: string,
): ReleaseAsset {
  const asset = release.assets.find((item) => item.name === assetName);
  if (!asset) {
    const available = release.assets.map((item) => item.name).join(", ");
    throw new Error(
      `Release asset not found: ${assetName}\nAvailable: ${available}`,
    );
  }
  return asset;
}

export async function downloadAsset(url: string): Promise<Uint8Array> {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Download failed: ${res.status} ${res.statusText}`);
  }
  return new Uint8Array(await res.arrayBuffer());
}
