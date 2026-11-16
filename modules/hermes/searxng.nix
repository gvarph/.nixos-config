{config, ...}: {
  age.secrets.searx_env.file = ../../secrets/searx_env.age;

  # Private metasearch. Hermes searches through DeepSeek (deepseek-web.nix);
  # this stays as the local alternative: `web.search_backend = "searxng"`.
  # Loopback only, so the bot limiter (which needs a real client IP) stays off.
  services.searx = {
    enable = true;
    environmentFile = config.age.secrets.searx_env.path;
    settings = {
      server = {
        bind_address = "127.0.0.1";
        port = 8888;
        secret_key = "$SEARX_SECRET_KEY";
        limiter = false;
        public_instance = false;
        image_proxy = false;
      };
      # Hermes queries /search?format=json.
      search.formats = ["html" "json"];
      general.instance_name = "nas1";
    };
  };
  systemd.services.searx.restartTriggers = [config.age.secrets.searx_env.file];

  # Only read when `web.search_backend` is "searxng".
  services.hermes-agent.environment.SEARXNG_URL = "http://127.0.0.1:8888";
}
