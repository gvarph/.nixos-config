let
  serv1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSGf6aVu23GcNSbF82+NzrO0MfknMt31so4XsHFd0vn gvarph@serv1";
  serv2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDE2TzrpOPaQ3Htd51zqES06PePo1E8fb9bemh9iQOJS gvarph@serv2";
in {
  "nas_auth.age".publicKeys = [serv1 serv2];
}
