{ pkgs, ... }:

{
  # #environment.systemPackages = with pkgs; [ vscode ];
  #imports = [
  ## fixes vscode ssh connection timeout
  #(fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
  #];
  ## enable vscode server
  #services.vscode-server.enable = true; 

  environment.systemPackages = with pkgs; [
    vscode
  ];



}
