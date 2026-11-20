final: prev: {
  audible-rs = prev.rustPlatform.buildRustPackage rec {
    pname = "audible-rs";
    version = "0.1.0-alpha.10";
    src = prev.fetchFromGitHub {
      owner = "mkb79";
      repo = "audible-rs";
      tag = "v${version}";
      hash = "sha256-y88PiQDmZKPfWCkoOmP3f8j/4h6pXqHfBigI6c1CrjI=";
    };
    cargoHash = "sha256-ZM2yGVniIAOZsNB23sBPWxuPR+lin8HO1KSfNVcJXc4=";
    nativeBuildInputs = [prev.pkg-config];
    # cargoSetupHook links these from nixpkgs instead of the vendored copies
    # (dontCargoUseSystemLibs opts out).
    buildInputs = [prev.openssl prev.aws-lc prev.sqlite];
    env.AUDIBLE_RELEASE_TAG = "v${version}";
    preCheck = ''
      export SSL_CERT_FILE=${prev.cacert}/etc/ssl/certs/ca-bundle.crt
    '';
    checkFlags = ["--skip=remove_requires_confirmation_or_yes"];
    meta = {
      description = "CLI and library for Audible";
      homepage = "https://github.com/mkb79/audible-rs";
      license = prev.lib.licenses.mit;
      mainProgram = "audible";
    };
  };
}
