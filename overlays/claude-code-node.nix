# Put node on claude's PATH. Plugin hooks (e.g. stripe@claude-plugins-official)
# run `node` directly and fail with "Executable not found in $PATH" without it.
# Suffixed so a project's own node (direnv/devshell) still wins.
# Must come after claude-code.overlays.default in flake.nix.
final: prev: {
  claude-code = prev.symlinkJoin {
    name = "claude-code-${prev.claude-code.version}";
    inherit (prev.claude-code) version meta;
    paths = [prev.claude-code];
    nativeBuildInputs = [prev.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/claude --suffix PATH : ${prev.lib.makeBinPath [prev.nodejs]}
    '';
  };
}
