{
  inputs,
  pkgs,
  ...
}: let
  pkgsStable = inputs.nixpkgs-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  az-cli-with-extensions = pkgsStable.azure-cli.withExtensions (with (inputs.nixpkgs-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system}).azure-cli-extensions; [fzf ai-examples azure-devops]);
in {
  home.packages = [
    az-cli-with-extensions
  ];
}
