{
  config,
  pkgs,
  ...
}: {
  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "DroidSansMono"
        "JetBrainsMono"
      ];
    })
    font-awesome
    powerline-fonts
    corefonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
  ];
}
