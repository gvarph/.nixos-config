{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;

    userName = "Filip Krul";
    userEmail = "gvarph006@gmail.com";

    maintenance.enable = true;
  };
}
