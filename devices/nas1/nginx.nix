{
  pkgs,
  config,
  lib,
  ...
}: let
  cloudflareRanges = import ./cloudflare-ips.nix;
in {
  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    # CrowdSec's Lua bouncer runs in the access phase (crowdsec.nix renders its
    # config): the firewall bouncer cannot see attackers behind Cloudflare.
    lua.enable = true;
    lua.extraPackages = ps: [ps.lua-cjson ps.lua-resty-http ps.lua-resty-openssl pkgs.lua-resty-string pkgs.crowdsec-lua-bouncer];
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;

    # Every vhost but ab.gvarph.com is Cloudflare-proxied, so without this the
    # access log and X-Forwarded-For carry edge IPs (fail2ban used to ban them).
    commonHttpConfig = ''
      real_ip_header CF-Connecting-IP;
      ${lib.concatMapStringsSep "\n" (r: "set_real_ip_from ${r};") cloudflareRanges}

      # CrowdSec nginx bouncer (upstream crowdsec_nginx.conf minus the unix-socket
      # map). Runs after real_ip, so remote_addr is the real client here.
      lua_shared_dict crowdsec_cache 50m;
      init_by_lua_block {
        cs = require "crowdsec"
        local ok, err = cs.init("/run/nginx/crowdsec-bouncer.conf", "crowdsec-nginx-bouncer/nixos-${pkgs.crowdsec-lua-bouncer.version}")
        if ok == nil then
          ngx.log(ngx.ERR, "[Crowdsec] " .. err)
          error()
        end
        ngx.log(ngx.ALERT, "[Crowdsec] Initialisation done")
      }
      init_worker_by_lua_block {
        cs = require "crowdsec"
        if string.lower(cs.get_mode()) == "stream" then
          cs.SetupStream()
        end
        if ngx.worker.id() == 0 then
          cs.SetupMetrics()
        end
      }
      access_by_lua_block {
        local cs = require "crowdsec"
        cs.Allow(ngx.var.remote_addr)
      }
    '';

    # Single backend: never eject it on a transient failure (e.g. a stale
    # browser tab still hitting the old /socket.io path after an immich
    # upgrade). Otherwise one failed websocket upgrade trips max_fails and
    # 502s the *entire* site with "no live upstreams".
    upstreams.immich.servers."127.0.0.1:2283" = {max_fails = 0;};

    virtualHosts = {
      # Catch-all default: any subdomain not matched below lands here and gets
      # a 404 instead of silently falling through to the alphabetically-first
      # vhost (which was Audiobookshelf at ab.gvarph.com).
      "catchall" = {
        default = true;
        useACMEHost = "gvarph.com";
        addSSL = true;
        locations."/".return = "404";
      };

      "immich.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com"; # or per-cert, see below
        locations."/" = {
          proxyPass = "http://immich";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      "ab.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:13378";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 5G;
            add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
          '';
        };
      };

      "ha.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://10.0.30.117:8123";
          proxyWebsockets = true;
          # Host / X-Forwarded-For / X-Forwarded-Proto come from
          # recommendedProxySettings. Do not set them again here: nginx does not
          # dedupe proxy_set_header within a level, so a second `Host` makes HA
          # reject every request with "Duplicate 'Host' header found".
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      "npm.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8181";
          proxyWebsockets = true;
        };
      };

      "paperless.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:13388";
          proxyWebsockets = true;
        };
      };

      "music-assistant.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8095";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "jellyfin.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "jf.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      # Jellystat has its own login; oauth2-proxy in front since it left the LAN port.
      "jellystat.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:13000";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "js.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:5055";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "grafana.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "id.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:1411";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      # Dedicated forward-auth endpoint. oauth2-proxy's nginx integration
      # (below) mounts /oauth2/* here; every protected vhost bounces its 401s
      # to auth.gvarph.com/oauth2/start. Keeping it on its own host + a
      # .gvarph.com cookie means SSO is shared across all protected services.
      "auth.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/".return = "404";
      };

      "qbit.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        # Now gated by oauth2-proxy (services.oauth2-proxy.nginx.virtualHosts
        # below) instead of the old LAN-only allow/deny.
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 100M;
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      "dawarich.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8090";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 100M;
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      # hevy2garmin dashboard (docker on 127.0.0.1:8124). No app login: the
      # container binds loopback only and auth is oauth2-proxy -> Pocket ID
      # (services.oauth2-proxy.nginx.virtualHosts below), like the other apps.
      "hevy.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8124";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      # 9router AI proxy (docker on 127.0.0.1:20128). Dashboard is behind
      # oauth2-proxy -> Pocket ID; the LLM API paths are opted out of SSO
      # (auth_request off) because clients send 9router's own API key there
      # (REQUIRE_API_KEY=true in docker_storage/9router/.env).
      "9router.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:20128";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
        locations."~ ^/(v1|v1beta|api/v1|api/v1beta|codex|responses)(/|$)" = {
          proxyPass = "http://127.0.0.1:20128";
          extraConfig = ''
            auth_request off;
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
            # SSE streaming and multi-minute completions.
            proxy_buffering off;
            proxy_read_timeout 10m;
            proxy_send_timeout 10m;
            # Large prompts / image inputs.
            client_max_body_size 100M;
          '';
        };
      };

      "ntfy.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8091";
          # Subscribers (phone app, HA) hold long-lived websocket/JSON streams.
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
            # Clients ping every 45s; the default 60s read timeout is too tight
            # a margin for slow cycles, and ntfy docs recommend 3m.
            proxy_read_timeout 3m;
          '';
        };
      };

      "fitness.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:3004";
          proxyWebsockets = true;
          extraConfig = ''
            # Profile pictures, exercise images, and backup restore uploads.
            client_max_body_size 100M;
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
            # The frontend image's own nginx already rate-limits at 5r/s, so the
            # X-Forwarded-For it sees must be the real client, not this proxy.
            proxy_set_header X-Forwarded-Ssl on;
          '';
        };
      };

      # Log intake for other hosts: Home Assistant's Vector add-on pushes its
      # journal here (VictoriaLogs' Elasticsearch bulk API) into VictoriaLogs,
      # which itself only listens on loopback. Basic auth from
      # secrets/vl_push_htpasswd.age; only the ingest paths are exposed.
      "logs.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        basicAuthFile = config.age.secrets.vl_push_htpasswd.path;
        locations."/insert/" = {
          proxyPass = "http://127.0.0.1:9428/insert/";
          extraConfig = ''
            client_max_body_size 20M;
          '';
        };
        locations."/".return = "404";
      };
      "crowdsec.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:3005";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "trek.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:3100";
          # TREK uses a websocket at /ws for real-time collaboration.
          proxyWebsockets = true;
          extraConfig = ''
            # File attachments up to 500 MB + backup archive uploads
            # (BACKUP_UPLOAD_LIMIT_MB defaults to 500).
            client_max_body_size 500M;
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      # --- music / books stack (docker_storage: navidrome, arr, shelfarr) ---

      # Navidrome web UI is gated by oauth2-proxy (see below) and auto-logs the
      # Pocket ID user in via X-Forwarded-User (ND_EXTAUTH_USERHEADER). The
      # Subsonic API and public shares must stay reachable for mobile apps that
      # authenticate with Navidrome credentials, so they opt out of auth_request.
      "navidrome.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:4533";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
            auth_request_set $preferred_username $upstream_http_x_auth_request_preferred_username;
            proxy_set_header X-Forwarded-User $preferred_username;
          '';
        };
        locations."/rest/" = {
          proxyPass = "http://127.0.0.1:4533";
          extraConfig = ''
            auth_request off;
            proxy_set_header X-Forwarded-User "";
          '';
        };
        locations."/share/" = {
          proxyPass = "http://127.0.0.1:4533";
          extraConfig = ''
            auth_request off;
            proxy_set_header X-Forwarded-User "";
          '';
        };
      };

      # Lidify has no authentication of its own: oauth2-proxy is the only gate.
      "lidify.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:5000";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      # slskd (Soulseek client feeding Lidarr via Soularr). It has its own
      # login, but oauth2-proxy stays in front like the rest of the stack.
      "slskd.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:5030";
          # The UI streams search results and transfer progress over a
          # SignalR websocket.
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      # SABnzbd (host_whitelist in sabnzbd.ini includes this name).
      "sab.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8085";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 100M; # manual .nzb uploads
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      "lidarr.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8686";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      # Sonarr/Radarr keep their own Forms login behind oauth2-proxy; Bazarr has
      # no auth of its own, so the proxy is its only gate.
      "sonarr.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8989";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "radarr.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:7878";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "prowlarr.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:9696";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "bazarr.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:6767";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      # Shelfarr has native OIDC (Pocket ID client, callback
      # /auth/oidc/callback) and a public request/login page, so it is NOT
      # behind oauth2-proxy.
      "shelfarr.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:5056";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 500M; # manual ebook/audiobook uploads
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      # WatchShelf sidecar (docker on 127.0.0.1:8081) for the Garmin app.
      # No oauth2-proxy: Connect IQ can't do interactive SSO, the sidecar
      # auths against ABS itself.
      "watchshelf.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8081";
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
            # /transcode streams an ffmpeg cut as it's produced.
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout 600s;
          '';
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "gvarph@gmail.com";

    certs."gvarph.com" = {
      domain = "*.gvarph.com";
      extraDomainNames = ["gvarph.com"];
      dnsProvider = "cloudflare";
      credentialFiles = {
        "CF_DNS_API_TOKEN_FILE" = config.age.secrets.cloudflare_dns_api_token.path;
      };
      group = "nginx";
    };
  };

  services.pocket-id = {
    enable = true;
    credentials.ENCRYPTION_KEY = config.age.secrets.pocket-id_encryption_key.path;
    dataDir = "/flash/pocket-id/";
    settings = {
      APP_URL = "https://id.gvarph.com";
      TRUST_PROXY = true;
    };
  };

  # Forward-auth gateway: puts a Pocket ID (OIDC) login in front of any service
  # that lacks decent built-in auth. Protect another service by adding its vhost
  # to `nginx.virtualHosts` below — nothing else needed.
  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    oidcIssuerUrl = "https://id.gvarph.com";

    # Public identifier from the Pocket ID OIDC client. Not a secret.
    clientID = "7fbac957-57dd-4ca5-919d-8655e2fb6b64";
    clientSecretFile = config.age.secrets.oauth2-proxy_client_secret.path;

    # Signs/encrypts the session cookie. Generate once (see notes), unrelated
    # to Pocket ID.
    cookie = {
      secretFile = config.age.secrets.oauth2-proxy_cookie_secret.path;
      domain = ".gvarph.com"; # share the session across all *.gvarph.com
    };

    # Single callback registered in Pocket ID; all protected hosts funnel here.
    redirectURL = "https://auth.gvarph.com/oauth2/callback";

    # Any account Pocket ID will authenticate is allowed. Tighten later with
    # per-vhost allowed_groups (needs the "groups" scope + a group in Pocket ID).
    email.domains = ["*"];

    reverseProxy = true;
    setXauthrequest = true;
    # nginx is the only thing that reaches oauth2-proxy (loopback); trust only
    # it to set X-Forwarded-* so clients can't spoof those headers.
    trustedProxyIP = ["127.0.0.1/32" "::1/128"];

    extraConfig = {
      # Permit post-login back-redirects to sibling subdomains.
      whitelist-domain = ".gvarph.com";
      # Pocket ID doesn't set email_verified=true; it's our trusted IdP and we
      # control every account, so accept its tokens anyway.
      insecure-oidc-allow-unverified-email = true;
    };

    nginx = {
      domain = "auth.gvarph.com";
      virtualHosts."qbit.gvarph.com" = {};
      virtualHosts."hevy.gvarph.com" = {};
      virtualHosts."9router.gvarph.com" = {};
      virtualHosts."navidrome.gvarph.com" = {};
      virtualHosts."lidify.gvarph.com" = {};
      virtualHosts."sab.gvarph.com" = {};
      virtualHosts."lidarr.gvarph.com" = {};
      virtualHosts."slskd.gvarph.com" = {};
      virtualHosts."jellystat.gvarph.com" = {};
      virtualHosts."sonarr.gvarph.com" = {};
      virtualHosts."radarr.gvarph.com" = {};
      virtualHosts."prowlarr.gvarph.com" = {};
      virtualHosts."bazarr.gvarph.com" = {};
    };
  };

  # LoadCredential reads the secret files only at process start, and the module
  # only auto-restarts on keyFile changes. Tie the unit to these secrets so
  # `nixos-rebuild switch` restarts it when either rotates.
  systemd.services.oauth2-proxy.restartTriggers = [
    config.age.secrets.oauth2-proxy_client_secret.file
    config.age.secrets.oauth2-proxy_cookie_secret.file
  ];
}
