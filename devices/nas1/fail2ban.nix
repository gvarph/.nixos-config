{...}: {
  services.fail2ban = {
    enable = true;
    # LAN VLANs and docker bridges: never ban ourselves or our own containers.
    ignoreIP = ["10.0.0.0/8" "172.16.0.0/12"];
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "48h";
    };

    # The module defaults every jail to the journal, but nginx writes its access
    # log to a file (error log -> journal), so these two need the file backend.
    jails = {
      # 404s on well-known probe paths (wp-login, phpmyadmin, cgi-bin, ...).
      nginx-botsearch.settings = {
        enabled = true;
        backend = "auto";
        logpath = "/var/log/nginx/access.log";
        maxretry = 3;
      };
      # 400s: malformed requests and plain HTTP thrown at :443.
      nginx-bad-request.settings = {
        enabled = true;
        backend = "auto";
        logpath = "/var/log/nginx/access.log";
        maxretry = 5;
      };
    };
  };
}
