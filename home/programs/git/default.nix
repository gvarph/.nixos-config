{
  config,
  lib,
  pkgs,
  ...
}: {
  home.file.".ssh/allowed_signers".text = lib.concatStringsSep "\n" (map (key: "* ${key}") (import ../../../ssh_keys.nix));

  programs.git = {
    enable = true;

    maintenance = {
      enable = true;
    };

    # signing = {
    #   key = "~/.ssh/id_ed25519.pub";
    #   signByDefault = true;
    # };

    settings = {
      user = {
        name = "Filip Krul";
        email = "gvarph006@gmail.com";
        signingkey = config.home.homeDirectory + "/.ssh/id_ed25519";
      };

      alias = {
        "prettylog" = "log --graph --all --pretty=format:'%C(magenta)%h%C(reset) %C(green)[%G?]%C(reset) %C(white)%an%C(reset) %C(dim)%ar%C(reset)%C(blue)  %D%C(reset)%n%s%n'";
        "smartblame" = "blame -C -C -C -w";
        "worddiff" = "diff --word-diff=color";
        "fpush" = "push --force-with-lease";
        "pushf" = "push --force-with-lease";
      };

      rerere.enabled = true;

      core = {
        compression = 9;
      };

      url = {
        "git@github.com:".insteadOf = "gh:";
        "git@ssh.dev.azure.com:v3/sharpgrid/Development/".insteadOf = "sga/";
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
      };

      log = {
        abbrevCommit = true;
      };

      branch = {
        sort = "-committerdate";
      };

      commit = {
        gpgSign = true;
      };

      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = config.home.homeDirectory + "/.ssh/allowed_signers";
      };
    };
  };
}
