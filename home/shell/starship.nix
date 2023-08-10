{
  imports = [
    ./starship-symbols.nix
  ];
  # Starship Prompt
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.starship.enable
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = { };
  };
}
