let
  serv1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSGf6aVu23GcNSbF82+NzrO0MfknMt31so4XsHFd0vn gvarph@serv1";
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnzQevH59i6xI9yeZvsRIIvN4zRHEHeQekPJDn5wuZ3 gvarph@desktop";
  nas1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwVmeHSQbpv6hMfnY3ZsXUPIbCWYtYf6oY1DLEuPC4y gvarph@nas1";
in {
  "homelab_k3s_token.age".publicKeys = [serv1 desktop nas1];
  "cloudflare_dns_api_token.age".publicKeys = [nas1];
}
