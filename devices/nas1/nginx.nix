{
  pkgs,
  custom,
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
      "qbit.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://localhost:8080";
          proxyWebsockets = true;
          extraConfig = ''
            allow 10.0.0.0/8;   # LAN VLANs only
            deny all;           # block public, even if :443 is port-forwarded
            client_max_body_size 100M;
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
}
