let
  serv1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSGf6aVu23GcNSbF82+NzrO0MfknMt31so4XsHFd0vn gvarph@serv1";
  serv2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDE2TzrpOPaQ3Htd51zqES06PePo1E8fb9bemh9iQOJS gvarph@serv2";
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWiHIItEoZ3zsMzBUL11dj2iOyQ5tQapVRmqvdHf7lx gvarph@nixos";
  nas1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEk8VogO8fXtVikJ3lIZ1CVN+i/xI0CIZXEYccmfRbKD gvarph@nas1";
in {
  "nas_auth.age".publicKeys = [serv1 serv2 desktop nas1];
  "homelab_k3s_token.age".publicKeys = [serv1 serv2 desktop nas1];
}
