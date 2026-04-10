{
  config,
  pkgs,
  lib,
  ...
}: let
  caveman = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "92f892f2b99744a4501f35bce9a2e384878e4877";
    hash = "sha256-EAlKoqJuTMib+gcLscMtpS8Zzq/D/LmIRoG3g/XKThc=";
  };
in {
  programs.opencode = {
    enable = true;
    settings = {
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
      };
    };
    skills = {
      caveman = "${caveman}/skills/caveman";
    };
  };
}
