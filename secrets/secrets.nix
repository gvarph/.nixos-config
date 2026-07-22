let
  serv1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSGf6aVu23GcNSbF82+NzrO0MfknMt31so4XsHFd0vn gvarph@serv1";
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnzQevH59i6xI9yeZvsRIIvN4zRHEHeQekPJDn5wuZ3 gvarph@desktop";
  nas1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwVmeHSQbpv6hMfnY3ZsXUPIbCWYtYf6oY1DLEuPC4y gvarph@nas1";
in {
  "homelab_k3s_token.age".publicKeys = [serv1 desktop nas1];
  # sha512crypt hash for the gvarph account (users.users.gvarph.hashedPasswordFile)
  "gvarph_password.age".publicKeys = [serv1 desktop nas1];
  "cloudflare_dns_api_token.age".publicKeys = [nas1];
  "pocket-id_encryption_key.age".publicKeys = [nas1];
  "oauth2-proxy_client_secret.age".publicKeys = [nas1];
  "oauth2-proxy_cookie_secret.age".publicKeys = [nas1];
  "grafana_mcp_token.age".publicKeys = [nas1];
  # gcp-oauth.keys.json (OAuth client id + secret) for the personal-gmail MCP.
  "personal-gmail-oauth-keys.age".publicKeys = [nas1];
  # Dedicated SSH key for the Hetzner Storage Box (restic offsite backup).
  "hetzner_storagebox_ssh_key.age".publicKeys = [nas1];
  # Restic repository password. ALSO stored outside this machine — the
  # repo must be recoverable when nas1 is dead.
  "restic_hetzner_password.age".publicKeys = [nas1];
}
