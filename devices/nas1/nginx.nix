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
          proxyPass = "http://localhost:80";
          proxyWebsockets = true;
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
          '';
        };
      };

      "ha.gvarph.com" = {
        forceSSL = true;
        useACMEHost = "gvarph.com";
        locations."/" = {
          proxyPass = "http://192.168.31.4:8123";
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
