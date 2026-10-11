{
  imports = [
    ./hermes.nix # core service: model, STT, dashboard, CLI wrappers
    ./sandbox.nix # rootless podman sandbox for terminal commands
    ./mcp.nix # every MCP server Hermes uses, plus unit ordering
    ./mcp-victoria.nix # VictoriaMetrics / VictoriaLogs MCP units
    ./fitness-mcp.nix # Garmin / Hevy MCP units
    ./searxng.nix # web_search backend
    ./camofox.nix # browser backend
  ];
}
