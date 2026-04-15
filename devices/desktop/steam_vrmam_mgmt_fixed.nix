{
  config,
  pkgs,
  ...
}: {
  boot.kernelPatches = [
    {
      name = "amdgpu-vram-cgroups-patch-1";
      patch = ./patches/9d928b2c5af078304205c12c71fec4904860d8cc.patch;
    }
    {
      name = "amdgpu-vram-cgroups-patch-2";
      patch = ./patches/9a02490c9f7938a4ed8950f0d61bcf677f67c07b.patch;
    }
    {
      name = "amdgpu-vram-cgroups-patch-3";
      patch = ./patches/1f24ddd4ffd04f47a04bd84987f36dc545bc7421.patch;
    }
    {
      name = "amdgpu-vram-cgroups-patch-4";
      patch = ./patches/f6bde8345b0c66e9cd81fa368343d4438ac9b3b0.patch;
    }
    {
      name = "amdgpu-vram-cgroups-patch-5";
      patch = ./patches/68f051af747220ac7d1d74bec8d79f2cb3a58304.patch;
    }
    {
      name = "amdgpu-vram-cgroups-patch-6";
      patch = ./patches/9260440455cd61f2c90cca172bc9d3e83bf1206d.patch;
    }
  ];

  environment.systemPackages = [
    (pkgs.callPackage ./dmemcg-booster.nix {})
    #(pkgs.callPackage ./plasma-foreground-booster.nix {kcgroups = pkgs.callPackage ./kcgroups.nix {};})
    (pkgs.callPackage ./kcgroups.nix {}) #not sure if this one is needed...
  ];

  systemd.packages = [
    (pkgs.callPackage ./dmemcg-booster.nix {})
  ];

  systemd.services.dmemcg-booster-system = {
    overrideStrategy = "asDropin";
    wantedBy = ["multi-user.target"];
  };

  systemd.user.services.dmemcg-booster-user = {
    overrideStrategy = "asDropin";
    wantedBy = ["graphical-session-pre.target"];
  };
}
