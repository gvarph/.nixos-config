{
  pkgs,
  lib,
  ...
}: let
  gcloudMcp = pkgs.writeShellScriptBin "gcloud-mcp-wrapped" ''
    export PATH=${lib.makeBinPath [pkgs.nodejs pkgs.google-cloud-sdk]}:$PATH
    exec ${pkgs.nodejs}/bin/npx -y @google-cloud/gcloud-mcp "$@"
  '';
in {
  programs.mcp.servers.gcloud = {
    command = "${gcloudMcp}/bin/gcloud-mcp-wrapped";
  };
}
