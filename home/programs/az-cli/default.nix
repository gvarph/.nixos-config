{pkgs-stable, ...}: let
  az-cli-with-extensions = pkgs-stable.azure-cli.withExtensions (with pkgs-stable.azure-cli-extensions; [fzf ai-examples azure-devops]);
in {
  home.packages = [
    az-cli-with-extensions
  ];
}
