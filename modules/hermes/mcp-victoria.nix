{
  lib,
  pkgs,
  ...
}: {
  # Shared Victoria* MCP servers for Hermes, Streamable HTTP on loopback.
  # INFO logs every full request/result (MBs per docs call), hence warn.
  systemd.services =
    lib.mapAttrs (name: s: {
      description = "${name} (Streamable HTTP, loopback)";
      wantedBy = ["multi-user.target"];
      after = [s.after];
      environment =
        s.env
        // {
          MCP_SERVER_MODE = "http";
          MCP_LISTEN_ADDR = "127.0.0.1:${toString s.port}";
          MCP_LOG_LEVEL = "warn";
        };
      serviceConfig = {
        ExecStart = lib.getExe pkgs.${name};
        DynamicUser = true;
        Restart = "on-failure";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      };
    }) {
      mcp-victoriametrics = {
        port = 8430;
        after = "victoriametrics.service";
        env = {
          VM_INSTANCE_ENTRYPOINT = "http://127.0.0.1:8428";
          VM_INSTANCE_TYPE = "single";
          # Docs come back inline from the tool; as resources they are ~8 MB/session.
          MCP_DISABLE_RESOURCES = "true";
        };
      };
      mcp-victorialogs = {
        port = 8431;
        after = "victorialogs.service";
        env.VL_INSTANCE_ENTRYPOINT = "http://127.0.0.1:9428";
      };
    };
}
