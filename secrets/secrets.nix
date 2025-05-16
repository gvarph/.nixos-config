let
  serv1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSGf6aVu23GcNSbF82+NzrO0MfknMt31so4XsHFd0vn gvarph@serv1";
in {
  "nas_auth.age".publicKeys = [serv1];
}
