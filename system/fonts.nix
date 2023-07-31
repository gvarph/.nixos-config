{ config, pkgs, ... }:

{
  fonts.fonts = with pkgs; [
    fira-code
    fira-mono
  ];
}