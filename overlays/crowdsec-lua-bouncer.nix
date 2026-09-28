# CrowdSec's Lua bouncer for nginx (crowdsecurity/lua-cs-bouncer); nixpkgs only
# ships the firewall bouncer. Laid out as a Lua module tree so the nginx
# module's lua_package_path (share/lua/5.1/?.lua) finds `crowdsec` and
# `plugins.crowdsec.*`; the ban/captcha pages live under share/.
final: prev: {
  # lua-resty-http needs resty.string, which nixpkgs only has inside openresty.
  lua-resty-string = prev.luajit_openresty.pkgs.toLuaModule (prev.stdenvNoCC.mkDerivation rec {
    pname = "lua-resty-string";
    version = "0.19";
    src = prev.fetchFromGitHub {
      owner = "openresty";
      repo = "lua-resty-string";
      tag = "v${version}";
      hash = "sha256-AMZo93bf8OJlOyqoCl6htzj67xP94oIru9ec+l5SVEo=";
    };
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/lua/${prev.luajit_openresty.luaversion}
      cp -r lib/. $out/share/lua/${prev.luajit_openresty.luaversion}/
      runHook postInstall
    '';
  });

  # toLuaModule marks it as a Lua module, which lua.withPackages filters on.
  crowdsec-lua-bouncer = prev.luajit_openresty.pkgs.toLuaModule (prev.stdenvNoCC.mkDerivation rec {
    pname = "crowdsec-lua-bouncer";
    version = "1.0.19";
    src = prev.fetchFromGitHub {
      owner = "crowdsecurity";
      repo = "lua-cs-bouncer";
      tag = "v${version}";
      hash = "sha256-SUIIt6cSGuGqAoMfM1DwBCeysrNgquBYecs1xtrH2og=";
    };
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      luadir=$out/share/lua/${prev.luajit_openresty.luaversion}
      mkdir -p $luadir $out/share/crowdsec-lua-bouncer
      cp -r lib/. $luadir/
      cp -r templates $out/share/crowdsec-lua-bouncer/
      runHook postInstall
    '';
  });
}
