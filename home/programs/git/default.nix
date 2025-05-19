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

    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    aliases = {
      gl = "log --graph --all --pretty=format:'%C(magenta)%h%C(reset) %C(white)%an %C(dim)%ar%C(reset)%C(blue)  %D%n%s%n' -n 30";
    };

    extraConfig = {
      core = {
        compression = 9;
      };

      url = {
        "git@github.com:".insteadOf = "gh:";
      };

      pull = {
        rebase = true;
        default = "current";
      };

      push = {
        default = "current";
        autoSetupRemote = true;
        followTags = true;
      };

      rebase = {
        autoStash = true;
        missingCommitsCheck = true;
      };

      log = {
        abbrevCommit = true;
      };
    };
  };
}
