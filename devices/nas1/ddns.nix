{
  config,
  pkgs,
  ...
}: {
  # Keeps the unproxied A record for gvarph.com (ab.gvarph.com is a CNAME to
  # it) pointed at the WAN IP. Replaces the oznu/cloudflare-ddns container.
  services.cloudflare-ddns = {
    enable = true;
    domains = ["gvarph.com"];
    proxied = "false";
    # A only, like the container did: there is no AAAA today and nas1's global
    # v6 addresses are rotating privacy temporaries.
    provider.ipv6 = "none";
    # The module insists on an env file; the token itself comes from the ACME
    # secret below, which favonia reads by path (trimmed, so agenix's newline is fine).
    credentialsFile = pkgs.writeText "cloudflare-ddns-env" "";
  };

  systemd.services.cloudflare-ddns.serviceConfig = {
    LoadCredential = "cf-token:${config.age.secrets.cloudflare_dns_api_token.path}";
    Environment = ["CLOUDFLARE_API_TOKEN_FILE=%d/cf-token"];
  };
}
