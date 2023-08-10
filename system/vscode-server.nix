{ pkgs, ... }:

#let
#  pkgs_with_old_code = import
#    (builtins.fetchTarball {
#      name = "nixos-unstable-2023-08-03";
#      url = "https://github.com/nixos/nixpkgs/archive/525595ebff10594d3d6071ca9953ba15f7e8b19c.tar.gz";
#      sha256 = "09chsdrlb3z5rsccxcw9h4a1vl7bm9jgxpg8v78ni5rgcm9api7r";
#    })
#    { config = { allowUnfree = true; }; };
#in
{

  # environment.systemPackages = [ pkgs_with_old_code.vscode ];

}
