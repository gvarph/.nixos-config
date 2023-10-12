{ pkgs, ... }:

let
  stable = import <nixos-stable> { config = { allowUnfree = true; }; };
in
{


            
  programs.nix-ld.enable = true;
  imports = [
	(fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
  ];
  services.vscode-server.enable = true;  
 
}

