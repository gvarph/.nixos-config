{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hermes.nix
    ./camofox.nix
  ];
}
