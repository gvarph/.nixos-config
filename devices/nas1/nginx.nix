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

    virtualHosts = {
      "immich.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com"; # or per-cert, see below
        locations."/" = {
          proxyPass = "http://localhost:2283";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; preload" always;
          '';
        };
      };

      "ab.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        serverAliases = ["audiobooks.gvarph.com"];
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
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
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
}
