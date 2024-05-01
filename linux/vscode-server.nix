{ pkgs, ... }:


{

  # imports = [
  #   (fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
  # ];

  #   services.vscode-server.enable = true;


  #environment.systemPackages = [
  #   pkgs.nodejs_16
  #   pkgs.nodejs_18
  #];

  # systemd.user = {
  #   paths.vscode-remote-workaround = {
  #     wantedBy = ["default.target"];
  #     pathConfig.PathChanged = "%h/.vscode-server/bin";
  #   };
  #   services.vscode-remote-workaround.script = ''
  #   for i in ~/.vscode-server/bin/*; do
  #     echo "Fixing vscode-server in $i..."
  #     ln -sf ${pkgs.nodejs_18}/bin/node $i/node
  #   done
  #   '';
  # };

}

