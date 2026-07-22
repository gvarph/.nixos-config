{
  pkgs,
  config,
  ...
}: {
  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;

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
          proxyPass = "http://localhost:13378";
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
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      "npm.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://localhost:8181";
          proxyWebsockets = true;
        };
      };

      "paperless.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://localhost:13388";
          proxyWebsockets = true;
        };
      };

      "music-assistant.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://localhost:8095";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "obs-couchdb.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://localhost:5984";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };
      "s3.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://localhost:3900";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            # Disable buffering to a temporary file.
            proxy_max_temp_file_size 0;
          '';
        };
      };
      "jellyfin.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://localhost:8096";
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
          proxyPass = "http://localhost:8096";
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
          proxyPass = "http://localhost:5055";
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
          proxyPass = "http://localhost:3000";
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
          proxyPass = "http://localhost:1411";
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
          proxyPass = "http://localhost:8080";
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
          proxyPass = "http://localhost:8090";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 100M;
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      "trek.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://localhost:3100";
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
