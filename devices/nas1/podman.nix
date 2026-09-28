{inputs, ...}: {
  # Rootful podman quadlets; the module turns virtualisation.podman on itself.
  # Docker stays alive next to it until the last compose stack is gone.
  imports = [inputs.quadlet-nix.nixosModules.quadlet];

  # `userns=auto` gives each container its own uid range from this pool, so a
  # container escape lands on ids that own nothing on the host.
  users.users.containers = {
    isSystemUser = true;
    group = "containers";
    subUidRanges = [
      {
        startUid = 2000000;
        count = 2000000;
      }
    ];
    subGidRanges = [
      {
        startGid = 2000000;
        count = 2000000;
      }
    ];
  };
  users.groups.containers = {};

  virtualisation.podman.dockerCompat = false;
}
