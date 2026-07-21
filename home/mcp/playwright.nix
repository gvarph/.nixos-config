{
  config,
  pkgs,
  lib,
  ...
}: let
  # We give playwright-mcp a writable user-data-dir under $HOME: it otherwise
  # tries to fetch/create a "chrome-for-testing" build + profile dir *inside*
  # the read-only nix store -> mkdir EROFS on NixOS.
  pwUserDataDir = "${config.home.homeDirectory}/.local/share/playwright-mcp/profile";

  # We run @playwright/mcp via npx rather than pkgs.playwright-mcp because
  # nixpkgs' playwright-mcp (0.0.76) is pinned against an older playwright-core
  # than the playwright-driver it runs against (1.61.x). 1.61.1 rejects the
  # --user-data-dir we need with "userDataDir is not supported in isolated
  # mode", crashing the server on startup. Fetching the package via npx makes it
  # bring its own matching playwright-core, sidestepping the skew. Pinned to a
  # known-good version for a bit of reproducibility; bump when needed. Downside:
  # not fully offline -> needs network on first run / npx cache miss. We still
  # point it at the Chromium from playwright-driver.browsers (read-only nix
  # store) via --executable-path so no browser download happens.
  #
  # The chromium-<rev> subdir version changes whenever nixpkgs bumps
  # playwright-driver, so resolve it with a glob at launch time rather than
  # hardcoding the revision (which used to go stale and silently break the
  # browser on every update). The store path itself stays nix-pinned; only the
  # version subdir is discovered. The glob matches chromium-<rev> but not
  # chromium_headless_shell-<rev>.
  playwrightMcpWrapped = pkgs.writeShellScriptBin "playwright-mcp-wrapped" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [pkgs.nodejs]}:$PATH
    shopt -s nullglob
    matches=(${pkgs.playwright-driver.browsers}/chromium-*/chrome-linux64/chrome)
    if [ ''${#matches[@]} -eq 0 ]; then
      echo "playwright-mcp: no chromium-* found in ${pkgs.playwright-driver.browsers}" >&2
      exit 1
    fi
    exec ${pkgs.nodejs}/bin/npx -y @playwright/mcp@0.0.78 \
      --browser chromium \
      --executable-path "''${matches[0]}" \
      --user-data-dir "${pwUserDataDir}" \
      "$@"
  '';
in {
  programs.mcp.servers.playwright = {
    command = "${playwrightMcpWrapped}/bin/playwright-mcp-wrapped";
    env = {
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    };
  };
}
