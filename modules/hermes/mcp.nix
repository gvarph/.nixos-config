{lib, ...}: let
  # Loopback MCP units (mcp-victoria.nix, fitness-mcp.nix) Hermes connects to.
  localUnits = ["mcp-victoriametrics.service" "mcp-victorialogs.service" "garmin-mcp.service" "hevy-mcp.service" "qbittorrent-mcp.service"];
in {
  # All of Hermes's MCP servers. Read tools only, each by explicit allowlist
  # (write tools are added only on request), except Hermes's own AgentMail inbox.
  services.hermes-agent = {
    mcpServers = {
      # Shared HTTP instances (mcp-victoria.nix), not a stdio copy per Hermes process.
      victoriametrics = {
        url = "http://127.0.0.1:8430/mcp";
        # No alerts/rules: without vmalert they are always empty ("nothing firing").
        tools.include = [
          "query"
          "query_range"
          "metrics"
          "metrics_metadata"
          "labels"
          "label_values"
          "series"
          "metric_statistics"
          "tsdb_status"
          "prettify_query"
          "explain_query"
          "documentation"
        ];
      };
      victorialogs = {
        url = "http://127.0.0.1:8431/mcp";
        tools.include = [
          "query"
          "hits"
          "facets"
          "field_names"
          "field_values"
          "stats_query"
          "stats_query_range"
          "streams"
          "stream_ids"
          "stream_field_names"
          "stream_field_values"
          "documentation"
        ];
      };
      # Read-only filter is enforced server-side (GARMIN_ENABLED_TOOLS, fitness-mcp.nix).
      garmin.url = "http://127.0.0.1:8432/mcp";
      hevy = {
        url = "http://127.0.0.1:8433/mcp";
        tools.include = [
          "get-training-summary"
          "get-workouts"
          "get-workout"
          "get-workout-events"
          "get-routines"
          "get-routine"
          "search-routines"
          "get-routine-folder"
          "get-exercise-template"
          "search-exercise-templates"
          "get-exercise-history"
          "get-body-measurements"
          "get-body-measurement"
        ];
      };
      # Loopback-only container (devices/nas1/arr.nix); SSE is the only HTTP transport it serves.
      qbittorrent = {
        url = "http://127.0.0.1:8434/sse";
        # add_torrent granted explicitly; everything else is read-only.
        tools.include = [
          "add_torrent"
          "list_torrents"
          "inspect_torrent"
          "get_torrent_files"
          "get_categories"
          "find_duplicates"
          "get_rss_feeds"
          "get_rss_rules"
          "get_search_plugins"
          "get_main_log"
          "get_peer_log"
          "get_system_info"
        ];
      };
      # Trek: plain OAuth (dynamic client registration), all tools; the scopes
      # approved on Trek's consent page decide what it may do. One-time login
      # as hermes: `hermes mcp login trek`.
      trek = {
        url = "https://trek.gvarph.com/mcp";
        auth = "oauth";
      };
      # Hermes's own inbox, so all tools. AGENTMAIL_API_KEY comes from hermes_env.
      agentmail = {
        url = "https://mcp.agentmail.to/mcp";
        headers.x-api-key = "\${AGENTMAIL_API_KEY}";
      };
    };
    # Typed mcpServers has no transport option.
    settings.mcp_servers.qbittorrent.transport = "sse";
    # Typed mcpServers has no oauth block. Fixed loopback callback, so the
    # login also works through an SSH tunnel.
    settings.mcp_servers.trek.oauth = {
      redirect_host = "127.0.0.1";
      redirect_port = 27899;
    };
  };

  systemd.services = lib.genAttrs ["hermes-agent" "hermes-backend"] (_: {
    wants = localUnits;
    after = localUnits;
  });
}
