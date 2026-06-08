{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
      };
    };
  };
}
