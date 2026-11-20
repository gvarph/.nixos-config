{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.mcp.servers.playwright = {
    command = lib.getExe pkgs.playwright-mcp;
    # A persistent profile under $HOME. It has to be set through the
    # environment: nixpkgs' wrapper turns on isolated mode unless this variable
    # is present, and isolated mode rejects the --user-data-dir flag ("userDataDir
    # is not supported in isolated mode"). The wrapper also points the server at
    # the Chromium from playwright-driver.browsers, so nothing is downloaded.
    env.PLAYWRIGHT_MCP_USER_DATA_DIR = "${config.home.homeDirectory}/.local/share/playwright-mcp/profile";
  };
}
