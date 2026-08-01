{
  config,
  lib,
  pkgs,
  ...
}: let
  user = config.home.username;

  # mba is the only Darwin host, and the only one that leaves the home LAN.
  # The LAN-resident boxes always reach each other directly, so they get the
  # plain entries below without the probe.
  roaming = pkgs.stdenv.hostPlatform.isDarwin;

  nas1Lan = "10.0.1.185";
  serv1Lan = "10.0.1.157";

  # `nc -z -w1` exits 0 only if the LAN address answers on :22 within a second,
  # so this matches exactly when we are on the home network. macOS ships nc at
  # /usr/bin/nc, which is on PATH for the shell ssh runs the probe under.
  onLan = host: addr: ''Match host ${host} exec "nc -z -w1 ${addr} 22"'';
in {
  programs.ssh = {
    enable = true;

    # The module's legacy defaults are all OpenSSH defaults anyway, and keeping
    # them on emits a deprecation warning; everything we care about is below.
    enableDefaultConfig = false;

    settings =
      {
        nas1 =
          if roaming
          # nas1 is what gvarph.com points at, so off-LAN we just go there.
          then {
            HostName = "gvarph.com";
            User = user;
          }
          else {
            HostName = nas1Lan;
            User = user;
          };

        serv1 =
          if roaming
          # serv1 has no public address; off-LAN we hop in through nas1 and
          # reach it on its LAN address from there.
          then {
            HostName = serv1Lan;
            User = user;
            ProxyJump = "gvarph.com";
          }
          else {
            HostName = serv1Lan;
            User = user;
          };

        # Rendered last, after every specific block, so the entries above win
        # where they overlap.
        "*" = {
          # Reuse a single TCP connection for every session to the same host.
          ControlMaster = "auto";
          # %C hashes host/port/user/localhost, so the socket path stays short
          # enough for the ~104 char unix socket limit even for long hostnames.
          ControlPath = "~/.ssh/master-%C";
          # Keep the master alive after the last session so follow-up
          # connections skip the handshake entirely.
          ControlPersist = "10m";
        };
      }
      // lib.optionalAttrs roaming {
        # These must be parsed before the plain blocks above: ssh takes the
        # first value it sees for each directive, so whatever these set wins
        # and the blocks above act as the off-LAN fallback.
        nas1-lan = lib.hm.dag.entryBefore ["nas1"] {
          header = onLan "nas1" nas1Lan;
          HostName = nas1Lan;
          User = user;
        };

        serv1-lan = lib.hm.dag.entryBefore ["serv1"] {
          header = onLan "serv1" serv1Lan;
          HostName = serv1Lan;
          User = user;
          # Claims ProxyJump before the fallback block can set it, otherwise
          # `Host serv1` would still route us through gvarph.com on the LAN.
          ProxyJump = "none";
        };
      };
  };
}
