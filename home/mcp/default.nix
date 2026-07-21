{...}: {
  # Each non-trivial MCP server (a wrapper script, host-conditional wiring, or
  # secrets) lives in its own file and contributes its own
  # `programs.mcp.servers.<name>` slice; the module system merges them. Only the
  # trivial HTTP servers stay inline below.
  imports = [
    ./playwright.nix
    ./gcloud.nix
    ./personal-gmail.nix
    ./grafana.nix
  ];

  programs.mcp = {
    enable = true;
    servers = {
      # "http" is the streamable-HTTP transport Claude Code expects for
      # remote servers; "remote" is NOT a valid type (Claude Code silently
      # drops the server and it never shows in /mcp).
      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
      };
      # Self-hosted TREK trip planner's built-in MCP endpoint. Auth is TREK's
      # own OAuth 2.1: Claude Code runs the browser consent flow on first
      # connect, so there's no token/header to configure here. Not behind the
      # oauth2-proxy gateway (that would hijack the MCP OAuth flow).
      trek = {
        type = "http";
        url = "https://trek.gvarph.com/mcp";
      };
    };
  };
}
