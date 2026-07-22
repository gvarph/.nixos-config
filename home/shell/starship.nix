{
  imports = [
    ./starship-symbols.nix
  ];
  # Starship Prompt
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.starship.enable
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    # Activates starship_transient_prompt_func (defined in fish.nix)
    enableTransience = true;
    settings = {
      gcloud.disabled = true;
      nix_shell.disabled = true;
      username.disabled = true;
    };
  };
}
