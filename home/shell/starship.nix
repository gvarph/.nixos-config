{
  imports = [
    ./starship-symbols.nix
  ];
  # Starship Prompt
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.starship.enable
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      gcloud.disabled = true;
      nix_shell.disabled = true;
      username.disabled = true;
    };
  };
}
