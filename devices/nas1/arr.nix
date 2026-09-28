{
  config,
  lib,
  pkgs,
  ...
}: let
  # slskd behind its own PIA tunnel is built but off: see docs/podman-migration.md
  # (PIA's primary token endpoint 504s and binhex never tries the fallback).
  slskdVpn = false;
in {
  age.secrets.qbittorrent_env.file = ../../secrets/qbittorrent_env.age;
  age.secrets.lidify_env.file = ../../secrets/lidify_env.age;

  # The *arr stack. The servarr network keeps the compose-era subnet and every
  # pinned address because the apps store each other by IP (download clients,
  # Prowlarr apps, Bazarr, lidify, soularr, shelfarr) or by container name
  # (prowlarr, flaresolverr). qBittorrent and slskd each go through their own
  # PIA WireGuard tunnel; everything else talks to the internet directly.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks builds;
    guard = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the datasets are missing.
      ConditionPathIsMountPoint = ["/flash/arr" "/tank/media"];
    };
    # linuxserver images start as root and drop to PUID/PGID; the media tree is
    # gvarph:users, so these share the host uid space (no user namespace).
    lscrEnv = {
      PUID = "1000";
      PGID = "100";
      TZ = "Europe/Prague";
    };
    lscr = {
      name,
      tag,
      ip,
      port,
      media ? true,
    }: {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "lscr.io/linuxserver/${name}:${tag}";
        environments = lscrEnv;
        networks = [networks.servarr.ref];
        inherit ip;
        publishPorts = ["127.0.0.1:${port}"];
        volumes =
          ["/flash/arr/${name}:/config"]
          ++ (
            if media
            then ["/tank/media:/data"]
            else []
          );
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };
  in {
    networks.servarr.networkConfig = {
      subnets = ["172.39.0.0/24"];
      gateways = ["172.39.0.1"];
    };

    # PIA WireGuard + port forwarding + qBittorrent in one image. Unprivileged:
    # NET_ADMIN, the fwmark sysctl and the tun device are all wg-quick needs.
    containers.qbittorrent = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/binhex/arch-qbittorrentvpn:5.2.3-3-01";
        environmentFiles = [config.age.secrets.qbittorrent_env.path];
        environments =
          lscrEnv
          // {
            VPN_ENABLED = "yes";
            VPN_PROV = "pia";
            VPN_CLIENT = "wireguard";
            # PIA port forwarding, auto-set as qBittorrent's listen port.
            STRICT_PORT_FORWARD = "yes";
            ENABLE_PRIVOXY = "no";
            # LAN + docker bridges + servarr (.39 is outside 172.16/12!).
            LAN_NETWORK = "10.0.0.0/8,172.16.0.0/12,172.39.0.0/24";
            NAME_SERVERS = "1.1.1.1,1.0.0.1";
            WEBUI_PORT = "8080";
            UMASK = "002";
          };
        addCapabilities = ["NET_ADMIN"];
        sysctl."net.ipv4.conf.all.src_valid_mark" = "1";
        devices = ["/dev/net/tun"];
        networks = [networks.servarr.ref];
        ip = "172.39.0.2";
        publishPorts = ["127.0.0.1:8080:8080"];
        volumes = [
          "/flash/arr/qbittorrent-binhex:/config"
          "/tank/media:/data"
        ];
        noNewPrivileges = true;
        # WebUI only answers once the tunnel is up and the port forward is set.
        healthCmd = "curl -fsS http://127.0.0.1:8080";
        healthInterval = "30s";
        healthTimeout = "10s";
        healthStartPeriod = "180s";
        healthRetries = 3;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };

    # Pauses well-seeded, old, high-ratio torrents; resumes them otherwise.
    builds.qbit-manager.buildConfig = {
      tag = "localhost/qbit-manager:latest";
      workdir = "${./qbit-manager}";
    };
    containers.qbit-manager = {
      autoStart = true;
      unitConfig = {
        After = ["qbittorrent.service"];
        Wants = ["qbittorrent.service"];
      };
      containerConfig = {
        image = builds.qbit-manager.ref;
        environments = {
          # By name on the servarr network; the WebUI whitelists 172.39.0.0/24.
          QBIT_URL = "http://qbittorrent:8080";
          SEED_THRESHOLD = "5";
          CHECK_INTERVAL = "600";
          AGE_THRESHOLD_HOURS = "24";
          PYTHONUNBUFFERED = "1";
        };
        networks = [networks.servarr.ref];
        ip = "172.39.0.18";
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.sonarr = lscr {
      name = "sonarr";
      tag = "4.0.20.3014-ls325";
      ip = "172.39.0.3";
      port = "8989:8989";
    };
    containers.radarr = lscr {
      name = "radarr";
      tag = "6.4.4.10685-ls317";
      ip = "172.39.0.4";
      port = "7878:7878";
    };
    containers.lidarr = lscr {
      name = "lidarr";
      tag = "3.1.0.4875-ls41";
      ip = "172.39.0.5";
      port = "8686:8686";
    };
    containers.bazarr = lscr {
      name = "bazarr";
      tag = "v1.6.1-ls364";
      ip = "172.39.0.6";
      port = "6767:6767";
    };
    containers.prowlarr = lscr {
      name = "prowlarr";
      tag = "2.6.5.5623-ls161";
      ip = "172.39.0.11";
      port = "9696:9696";
      media = false;
    };
    # Usenet client (Newshosting); nginx sab.gvarph.com -> :8085.
    containers.sabnzbd = lscr {
      name = "sabnzbd";
      tag = "5.1.3-ls273";
      ip = "172.39.0.13";
      port = "8085:8080";
    };

    # Cloudflare bypass for Prowlarr; reached by name, nothing published.
    containers.flaresolverr = {
      autoStart = true;
      containerConfig = {
        image = "ghcr.io/flaresolverr/flaresolverr:v3.5.2";
        environments = {
          LOG_LEVEL = "info";
          LOG_HTML = "false";
          CAPTCHA_SOLVER = "none";
          TZ = "Europe/Prague";
        };
        networks = [networks.servarr.ref];
        ip = "172.39.0.12";
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    # Last.fm-driven Lidarr suggestions; nginx lidify.gvarph.com -> :5000.
    containers.lidify = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/thewicklowwolf/lidify:0.2.11";
        environmentFiles = [config.age.secrets.lidify_env.path];
        environments =
          lscrEnv
          // {
            mode = "LastFM";
            lidarr_address = "http://172.39.0.5:8686";
            root_folder_path = "/data/music/";
            quality_profile_id = "1";
            metadata_profile_id = "1";
          };
        networks = [networks.servarr.ref];
        ip = "172.39.0.14";
        publishPorts = ["127.0.0.1:5000:5000"];
        volumes = ["/flash/arr/lidify:/lidify/config:U"];
        # Only talks to Lidarr's API; its entrypoint chowns to PUID.
        userns = "auto:size=65536";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    # Soulseek client; nginx slskd.gvarph.com -> :5030. 50300 is the peer port
    # and stays open to the world (see default.nix firewall).
    # VPN-only binhex image (same base as the qbittorrent one) that slskd
    # shares its network namespace with. It takes over slskd's servarr address
    # so soularr's slskd URL still works; the API/web port comes in over eth0
    # (VPN_INPUT_PORTS), peers over PIA's forwarded port (see slskd-port-sync).
    containers.slskd-vpn = {
      autoStart = slskdVpn;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/binhex/arch-privoxyvpn:4.2.0-1-01";
        environmentFiles = [config.age.secrets.qbittorrent_env.path];
        environments =
          lscrEnv
          // {
            VPN_ENABLED = "yes";
            VPN_PROV = "pia";
            VPN_CLIENT = "wireguard";
            STRICT_PORT_FORWARD = "yes";
            ENABLE_PRIVOXY = "no";
            ENABLE_SOCKS = "no";
            LAN_NETWORK = "10.0.0.0/8,172.16.0.0/12,172.39.0.0/24";
            NAME_SERVERS = "1.1.1.1,1.0.0.1";
            VPN_INPUT_PORTS = "5030";
            UMASK = "002";
          };
        addCapabilities = ["NET_ADMIN"];
        sysctl."net.ipv4.conf.all.src_valid_mark" = "1";
        devices = ["/dev/net/tun"];
        networks = [networks.servarr.ref];
        ip = "172.39.0.16";
        publishPorts = ["127.0.0.1:5030:5030"];
        volumes = ["/flash/arr/slskd-vpn:/config"];
        noNewPrivileges = true;
        # The forwarded port is only written once the tunnel is up.
        healthCmd = "test -s /tmp/getvpnport";
        healthInterval = "30s";
        healthTimeout = "5s";
        healthStartPeriod = "180s";
        healthRetries = 3;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };
    containers.slskd = {
      autoStart = slskdVpn;
      unitConfig =
        guard
        // {
          # Lives in the VPN container's netns, so it must follow its lifecycle.
          After = guard.After ++ ["slskd-vpn.service"];
          Requires = ["slskd-vpn.service"];
          PartOf = ["slskd-vpn.service"];
          Wants = ["slskd-port-sync.service"];
        };
      containerConfig = {
        image = "docker.io/slskd/slskd:0.26.0";
        user = "1000:100";
        environments.TZ = "Europe/Prague";
        networks = ["container:slskd-vpn"];
        volumes = [
          "/flash/arr/slskd:/app"
          "/tank/media:/data"
        ];
        noNewPrivileges = true;
        healthCmd = "wget -q -O - http://localhost:5030/health";
        healthInterval = "60s";
        healthTimeout = "3s";
        healthStartPeriod = "60s";
        healthRetries = 3;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };
    containers.soularr = {
      autoStart = true;
      unitConfig =
        guard
        // {
          After = guard.After ++ ["slskd.service"];
          Wants = ["slskd.service"];
        };
      containerConfig = {
        # `latest` tracks main; pinned to the build that was running on 2026-09-28.
        image = "docker.io/mrusse08/soularr@sha256:9d17bdc35108afd747c4862dc32a0c1cba821638d170e1374188a977ce255c76";
        user = "1000:100";
        environments = {
          TZ = "Europe/Prague";
          SCRIPT_INTERVAL = "300";
          WEBUI_ENABLED = "true";
        };
        networks = [networks.servarr.ref];
        ip = "172.39.0.17";
        publishPorts = ["127.0.0.1:8265:8265"];
        volumes = [
          "/flash/arr/soularr:/data"
          "/tank/media/completed/slskd:/downloads"
        ];
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };
  };

  # PIA hands out one forwarded port per tunnel (stable for months, but not
  # fixed). Push it into slskd's runtime listen port after each start and
  # every few minutes, logging in with the web credentials from slskd.yml.
  systemd.services.slskd-port-sync = {
    after = ["slskd.service"];
    requisite = ["slskd.service"];
    path = [config.virtualisation.podman.package] ++ (with pkgs; [yq-go curl jq]);
    serviceConfig.Type = "oneshot";
    script = ''
      cfg=/flash/arr/slskd/slskd.yml
      api=http://127.0.0.1:5030/api/v0
      port=$(podman exec slskd-vpn cat /tmp/getvpnport)
      [[ $port =~ ^[0-9]+$ ]] || { echo "no forwarded port yet"; exit 1; }
      token=$(yq -o=json '{"username": .web.authentication.username, "password": .web.authentication.password}' "$cfg" \
        | curl -fsS -H 'Content-Type: application/json' -d @- "$api/session" | jq -r .token)
      current=$(curl -fsS -H "Authorization: Bearer $token" "$api/options" | jq -r .soulseek.listenPort)
      if [ "$current" != "$port" ]; then
        curl -fsS -X PATCH -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
          -d "{\"soulseek\":{\"listenPort\":$port}}" "$api/options" >/dev/null
        echo "slskd listen port $current -> $port"
      fi
    '';
  };
  systemd.timers.slskd-port-sync = {
    wantedBy = lib.optional slskdVpn "timers.target";
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
    };
  };

  systemd.services = {
    qbittorrent.restartTriggers = [config.age.secrets.qbittorrent_env.file];
    lidify.restartTriggers = [config.age.secrets.lidify_env.file];
  };
}
