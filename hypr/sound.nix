{pkgs, ...}: {

  #imports = {
  #  ./sound.nix
  #}  
environment.systemPackages = [
    pkgs.pavucontrol
    pkgs.pulseaudio
  ];  




# rtkit is optional but recommended
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  # If you want to use JACK applications, uncomment this
  #jack.enable = true;
};

}
