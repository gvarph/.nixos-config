{
  config,
  pkgs,
  ...
}: let
  az-cli-with-extensions = pkgs.azure-cli.withExtensions (with pkgs.azure-cli-extensions; [fzf ai-examples azure-devops]);
in {
  home.packages = [
    az-cli-with-extensions
  ];
}
