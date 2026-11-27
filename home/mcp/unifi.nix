{
  pkgs,
  lib,
  osConfig,
  ...
}: {
  # sirkirby/unifi-mcp Network server against the UniFi OS gateway. Logs in as a
  # View Only local account, so the controller refuses writes regardless.
  programs.mcp.servers = lib.mkIf (osConfig.networking.hostName == "nas1") {
    unifi = {
      command = "${pkgs.uv}/bin/uvx";
      args = ["unifi-network-mcp==0.50.3"];
      env = {
        UV_PYTHON = lib.getExe pkgs.python313;
        UNIFI_HOST = "10.0.1.1";
        UNIFI_USERNAME = "mcp";
        # Read by the server itself; trailing newlines are dropped.
        UNIFI_PASSWORD_FILE = osConfig.age.secrets.unifi_mcp_password.path;
        # Self-signed cert (CN=unifi.local, expires 2027-08-30); re-pin on renewal.
        UNIFI_SSL_FINGERPRINT = "9B:62:13:9C:9E:FE:BD:FE:CD:E6:46:8B:7D:1D:A0:F9:3B:5B:A6:1A:58:18:BD:DD:6C:0D:EA:D7:69:0E:9D:EA";
        # Belt and braces on top of the View Only role.
        UNIFI_POLICY_CREATE = "false";
        UNIFI_POLICY_UPDATE = "false";
        UNIFI_POLICY_DELETE = "false";
        # Granted for RF scans; also unlocks reboot/upgrade/radio edits (each still preview+confirm).
        UNIFI_POLICY_NETWORK_DEVICES_UPDATE = "true";
      };
    };
  };
}
