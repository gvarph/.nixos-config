{
  config,
  pkgs,
  ...
}: {
  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs;
    [
      font-awesome
      powerline-fonts
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
