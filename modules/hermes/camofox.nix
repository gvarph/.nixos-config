{config, ...}: let
  subnet = "10.90.3.0/24";
  gateway = "10.90.3.1";
  # Never reachable from the browser: LAN, host, CGNAT/Tailscale, link-local/metadata.
  privateNets = ["10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" "100.64.0.0/10" "169.254.0.0/16"];
in {
  # Camofox: anti-detect Firefox (Camoufox) behind a REST API, used by Hermes's
  # browser tools. No published image, so built from the pinned upstream commit.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) builds networks;
    src = builtins.fetchGit {
      url = "https://github.com/jo-inc/camofox-browser.git";
      rev = "46b6eb044387142af90cc170436244ad65fffaf1";
    };
  in {
    # Fixed subnet so the egress filter below can match it.
    networks.camofox.networkConfig.subnets = [subnet];

    # Dockerfile.ci downloads Camoufox at build time (the plain Dockerfile needs `make`).
    builds.camofox.buildConfig = {
      tag = "localhost/camofox:46b6eb0";
      workdir = "${src}";
      file = "${src}/Dockerfile.ci";
      buildArgs = ["TARGETARCH=amd64"];
    };

    containers.camofox = {
      autoStart = true;
      containerConfig = {
        image = builds.camofox.ref;
        networks = [networks.camofox.ref];
        # Loopback only; Hermes reaches it as CAMOFOX_URL.
        publishPorts = ["127.0.0.1:9377:9377"];
        environments = {
          CAMOFOX_CRASH_REPORT_ENABLED = "false";
          # Browser starts on first use and exits after 5 idle minutes (~40 MB idle).
          BROWSER_IDLE_TIMEOUT_MS = "300000";
          MAX_SESSIONS = "4";
          MAX_TABS_GLOBAL = "12";
        };
        # `sh -c` as PID 1 ignores SIGTERM; an init forwards it (else 10 s then SIGKILL).
        runInit = true;
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };
  };

  # Hermes skips its private-URL guard for a local sidecar, so block the LAN here.
  # mangle/PREROUTING: netavark never touches it, so its own rules can't bypass this.
  networking.firewall.extraCommands = ''
    iptables -w -t mangle -N camofox-egress 2>/dev/null || iptables -w -t mangle -F camofox-egress
    iptables -w -t mangle -A camofox-egress -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
    iptables -w -t mangle -A camofox-egress -d ${gateway} -p udp --dport 53 -j RETURN
    iptables -w -t mangle -A camofox-egress -d ${gateway} -p tcp --dport 53 -j RETURN
    ${builtins.concatStringsSep "\n" (map (n: "iptables -w -t mangle -A camofox-egress -d ${n} -j DROP") privateNets)}
    iptables -w -t mangle -C PREROUTING -s ${subnet} -j camofox-egress 2>/dev/null \
      || iptables -w -t mangle -A PREROUTING -s ${subnet} -j camofox-egress
  '';
  networking.firewall.extraStopCommands = ''
    iptables -w -t mangle -D PREROUTING -s ${subnet} -j camofox-egress 2>/dev/null || true
    iptables -w -t mangle -F camofox-egress 2>/dev/null || true
    iptables -w -t mangle -X camofox-egress 2>/dev/null || true
  '';

  services.hermes-agent = {
    environment.CAMOFOX_URL = "http://127.0.0.1:9377";
    settings.browser.cloud_provider = "camofox";
  };
  systemd.services.hermes-agent = {
    wants = ["camofox.service"];
    after = ["camofox.service"];
  };
}
