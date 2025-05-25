{
  config,
  pkgs,
  username,
  inputs,
  ...
}: {
  imports = [
    # fix vs code server
    ./linux/vscode-server.nix

    # set locale
    ./linux/locale.nix

    # set up ssh server
    ./linux/features/ssh.nix

    #./linux/fonts.nix
  ];

  # Enable flake support
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    description = "Filip Krul";
    extraGroups = ["networkmanager" "wheel" "nixeditors" "docker" "openvpn"];
    packages = [];
    shell = pkgs.fish;
    home = "/home/${username}";
    hashedPassword = "$6$nDwj1uS.gupSHUbz$c5Noj0SE.ala4h/sgfREH2TlBo92ry8EBaiCiGvsVyIqE7jlwIb4KtLHypjkYwwIawgGfy5H0KS7lpTyFa/QJ0";

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLHO/mS3CxMS6TieqaFEqPcP1uJcgkGYBcINY9GceosG4Wyx+q1Y/K2bt+VDjM2cap7Y7njdNMDK2F+G2o8T/Oihhi7qk/kGgavOsTXp0XSQqzvaE0yeE3uGUAE4c+WMCGi97gd8R3robQSl6UlrzGcKIaqVJeZAO1Vs5trbX0yjnmGtiXcUAdZvw5bBxNmp49UVBylJjXCQd+y/neqeP3JVuEiEeLubqFBQEE5p5XVYm5YqA+dfvysQR9sNC5tPurpDCPljxQol6EYmCAoWOTyJ9oe4Ps7IXnpMy+lfaw3Sfl7Z+r0+FqLSnt2U4j92NNDTSnQRcysF3mcqacHPKptSidcCKF2JYJPfx/mYdxrCFq5ajA4iIy+L7tpVa/5paLolrvb1vgYDWd3eWpQqPNifPR3IYHFebWs6jH3J5sNoI5qd44S0k9vN47yztrn9UdTpdxj3G4USDdleMs7Ukp9q+gGacvNi37etulBB0BNj1XB3Pc8cNHWeF7MIvxGh8= gvarp@Gvarph_D"

      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxQd1E2P6RVXJRBxMcV/Zmm683vLxpkfxPgvkYyBTmhYtohvMBs9DFxDsr5ual/kWb5UCv8Ae80GS3V1bXH4lrm05hcP3FJA1UCUpQ9GQZMjjp6F72GcXcdjXmf98eWZE1+V3xWd206n9GjZbo2edErON7TqwWBPMfo6RSJlSvo3lrksN6/5V9Ja/ZdhLK0uCehWEwavlG1BfUMhLqeXBJEu2N4+OG2DqNkThc7pMyg/Yiwn2vQl03H4C0R6ZnNOagJ07hFit41073gvyUqQeGGVyoYq0PW9WbmQTb9u3F2lWre052y3uv+EruhsEXBCSQELyZE6DWtfy/Tzr7fCF7xSdlAkOTjsGaSkpUbjx71HKbWDM251oe8BzUIy4u4QPOJjTzc1CPz3kEsdCnI0WoYnb036iwty/pxmWJsI5b1n+9fiAEs8wDauSjdpeTR7TkqgSaIbAbkg5ZelqTvQcOEnHkYoE4hYclSZQXUQHhXMfmE0zaxlkZE62ex0vXgi0= user@DESKTOP-A3LQ8JG  "

      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4u9SPBAsZsMTsUA7vbh2uplhK9R6fy3uPxQzc1iEi6oX4M8wdX48DZlEZtZV+GH63jS+LLM/rcPCcTfKFrtzcEK0f+tOUCQuJr78IKJYc2S1qF1TBiGgBfFLGO0Ih+Y0iQsww1t4iT2eiM68X5ztWZ6ntzSU7Lcw4R7/RKq0zjD9wP/uYtdvipRM7JJHU1MLJfE/ckEsUeoV7YyMWdBKTMHvsM5pw4M0WsbtqkUJ7xGh7bxlf6Gr6KFpGObnTSxG6W/YsHQ6mzx/ybUH04gbPd9/fBR0IJomikzEz8m/kXnWzYW1f6wrExW7BAd2QgwErJGE1UQg9ew7/gINokjFcObcjatzpu0EGvS5RhcPYLMtXFaLu2rdmEHhbMvGAsNo84MxrK8+o4qRd/jh/OwtvlHM0s1ah3m7DRIn5R22qOzOl0CRAan480QCNEd4ZB1bSMVLnWgAAF3sIr4zRVsUC/le56Uf6F4YfIL14SOODkqdedbBkuSQK9s35fO2mGZs= gvarph@Filips-Air"

      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuRwAmg4m/BYlsvz66HRNuVkzUVPNQyJSKIkDo6fTOhLqyYx13o2mZ5AMUhkpgcy+ty0jeG4pfAqtDuQsfQKP65uBwQ7Z43bvHJUEOuqTRgAxYHueXjm+8zh70SKgcpmfkbpkQpkzPzCqmUltNFTh7H5p7Gt9AnquVR2Z0XDKZPtFBJXGp4ZIzUV+MXU1dla1AeevbYi1djMzEnRzCJX/QfbESkio/rrjih3e+L5HSwN2nthccSOB6HDh+Ph76e8z1pU3U02xG182sPLXgBj/7MGFZrSt8X1+bAPX+pP6Yzzs6HjZC7TKRcZWaNnW6mdBlYswL2oFtvYJS1zPnWi50TfoUPkKZxJiwaLD97viSqkf+Ue8IM3kAlYLdAAVYZFoO4DK3RuuDfKftD3FhkEPJUS00hubwVwv/0gqjSS1cO3gyUA5v9LLb5a/k04PXK41XKufThQ+JkmyyELWNhPFPi4+i1liaAwBYYkU6OzPDz+eN1VCB8YBE2Z0SpDCU9F0= gvarph@deskt"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvKRp9b8bg4pX3OTEGiCX5g3eED169m/bmiV3jM+VfY gvarph@DESKTOP-86UCT0V"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKAEtmLivQKX77XCGfszdGaMEN3pY27x8L981cwl0jHD gvarph@DESKTOP-86UCT0V" # id_main

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaLojLN0qJaHr6BsSnypa0ktTo0g0KpHCT0lJ7VyLG7 gvarph@Filips-MacBook-Air.local"

      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDArVOXa9U7ovAhOrv6ItihS17T1GqutOA0TXmeFwPuw8KQlowtGNTGNkwHKXVoyefwP/g+gXZPZyv7LTCSi013ZTlotd0F/mYo/tP3S6Kz88J6Hter2y9oqS1EZtZo4yG4p7IRLAz4aioHGjujCo14eAL5OzVJyosslDWo5Bh1Pij7jQpdo5eumatPItLWHKPoo0wOvlVOSFeZDEdw696R3uk65PV6YxakiO/JZi4zITNDIt3graBDVrqMrwTGBY5dcxYPjRrEcbqSXJc0LJ9C2GDEQZsQZR5iUjUlKcnMUzk8KpyuwNuJeESBEOsS2++jQUmodR9pnHSaF7wrYCbriI4f7hh82n1Jg+YsMZ1S/L264txqfbmo5AJZSUPbdTtMic6rS4iBMiGBlOu+R4t6ky2YbCim6QLrpmM/SjwHIGHCku8Za2CKoplC3hpjlOsPYpA1EAeIQGvU0oJuTLJAQzHLowGoOn5Q1jtvx6o9KWxHJmyBVS8bbU9NAyEYF3U= gvarph@serv2"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcG90VcEnUkA8qjtQXZ9WHSob8lDm9gjWZNCTlmAnhh deck@steamdeck"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSGf6aVu23GcNSbF82+NzrO0MfknMt31so4XsHFd0vn gvarph@serv1"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDE2TzrpOPaQ3Htd51zqES06PePo1E8fb9bemh9iQOJS gvarph@serv2"
    ];
  };

  programs.nix-ld.enable = true;

  # may break 16-bit apps
  boot.kernel.sysctl = {"vm.max_map_count" = 2147483642;};

  system.stateVersion = "23.11";

  # Nix home manager configuration
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.${username} = {
    # home.enableNixpkgsReleaseCheck = false;

    imports = [
      # set user and enable home-manager
      (import ./home {inherit config pkgs inputs username;})
    ];
  };

  programs.fish.enable = true;
}
