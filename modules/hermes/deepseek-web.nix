{pkgs, ...}: let
  # Community plugin: DeepSeek's Search & Fetch API as a Hermes web backend
  # ("deepseek"). Pinned to the commit Hermes's catalog lists
  # (plugin-catalog/deepseek-search-fetch.yaml).
  deepseekSearchFetch =
    pkgs.runCommand "deepseek-search-fetch" {
      src = pkgs.fetchFromGitHub {
        owner = "JasonSwindle";
        repo = "hermes-deepseek-search-fetch";
        rev = "95738a9913ac6595b73e655fad1d79414b1311dc";
        hash = "sha256-CZxRifRyBqjzdTGDDw7H4uBstEySq1kLcmQ4jeEuw2w=";
      };
    } ''
      mkdir $out
      cp $src/{plugin.yaml,LICENSE,__init__.py} $out/
    '';
in {
  # web_search and web_extract through DeepSeek Search & Fetch. Uses the
  # DEEPSEEK_API_KEY in hermes_env; $0.75 per 1,000 successful requests.
  # Both keys are set explicitly: a leftover value in the deep-merged
  # config.yaml would otherwise win over a shared `web.backend`.
  services.hermes-agent = {
    extraPlugins = [deepseekSearchFetch];
    settings.web = {
      search_backend = "deepseek";
      extract_backend = "deepseek";
      # Never fall back to public keyless APIs.
      keyless_fallback = false;
      keyless_rescue = false;
    };
  };
}
