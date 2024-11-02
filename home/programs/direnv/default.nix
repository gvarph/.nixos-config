{
  config,
  pkgs,
  ...
}: {
  programs.direnv = {
    enable = true;
    #    enableFishIntegration = true; - Enabling fish also enables fish integration for direnv
    nix-direnv = {
      enable = true;
    };
  };
}
