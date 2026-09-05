{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    plugins = {
      dragon =
        pkgs.fetchFromGitHub {
          owner = "R4Sput1n";
          repo = "yazi-dragon";
          rev = "67f9844946e3fbfd7b3535e6ffb7327c5a69c82f";
          hash = "sha256-nPMMXtxYPFsTAvMbmR/LVAV9KdhV3TEYfnoDoSIEETI=";
        }
        + "/dragon.yazi";
    };
  };
}
