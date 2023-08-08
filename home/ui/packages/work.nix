{ pkgs, ... }:
{

  home.packages = with pkgs; [
    vscode

    google-chrome

    slack

  ];

}
