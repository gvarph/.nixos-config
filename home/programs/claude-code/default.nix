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

  vmSkills = pkgs.fetchFromGitHub {
    owner = "VictoriaMetrics";
    repo = "skills";
    rev = "410c475d8b48621c1d1859a3234f859887cea412";
    hash = "sha256-xpP9NW6YZW3qLB06MAcGuhpJmvv1qAVASeFo1VNv/ko=";
  };

  # Wrapper providing the statusline's runtime deps on PATH and running it
  # under bash. The script itself is not strict-mode safe, so we launch it
  # directly rather than via writeShellApplication.
  statusline = pkgs.writeShellScript "claude-statusline" ''
    export PATH="${lib.makeBinPath (with pkgs; [jq git gawk coreutils])}:$PATH"
    exec ${pkgs.bash}/bin/bash ${./statusline.sh} "$@"
  '';
in {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    # settings.json is intentionally left unmanaged: Claude Code mutates it at
    # runtime (/model, /config, ...). It already points statusLine.command at
    # ~/.claude/statusline-command.sh, which we materialise below.
    settings = {
    };
    skills = {
      caveman = "${caveman}/skills/caveman";
    };
    plugins = [
      "${vmSkills}/plugins/query"
      "${vmSkills}/plugins/diagnostics"
    ];
  };

  # Materialise the statusline wrapper at the path settings.json references.
  home.file.".claude/statusline-command.sh".source = statusline;
}
