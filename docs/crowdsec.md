# CrowdSec on nas1

Engine: `devices/nas1/crowdsec.nix` (sources, whitelist, escalating ban profiles, ntfy
notifications). Dashboard: crowdsec-web-ui at crowdsec.gvarph.com (`crowdsec-web-ui.nix`).

## Two bouncers, two reasons

- **Firewall bouncer** (iptables): drops packets from banned IPs on every port. Covers SSH and
  anything that reaches nas1 directly (ab.gvarph.com, LAN).
- **nginx bouncer** (Lua, `overlays/crowdsec-lua-bouncer.nix`, hooked in `nginx.nix`): every
  other vhost is Cloudflare-proxied, so packets come from Cloudflare edges (whitelisted) and the
  attacker's IP only exists in `CF-Connecting-IP`. nginx's `real_ip` puts it in `remote_addr`
  and the bouncer enforces on that: banned IPs get the 403 ban page on all vhosts. Stream mode,
  decisions pulled from the LAPI every 10s.

The bouncer's config is rendered into `/run/nginx/crowdsec-bouncer.conf` by an
`ExecStartPre` of nginx (API key from `secrets/crowdsec_nginx_bouncer_key.age`); the key is
registered by `crowdsec-nginx-bouncer-register.service` on every start. Rotate the key by
re-encrypting the secret and switching.

- Skip the check for a path: `EXCLUDE_LOCATION=/api/health,/other` in the rendered config
  template (`crowdsec.nix`).
- Only ban decisions are enforced by nginx (`BOUNCING_ON_TYPE=all` with
  `FALLBACK_REMEDIATION=ban`); captcha would need Turnstile keys.
- AppSec/WAF is deliberately off (`APPSEC_URL=` empty); enabling it means the appsec
  acquisition + collections in `crowdsec.nix` and `APPSEC_URL=http://127.0.0.1:7422` here.

## Remote logs via VictoriaLogs

Home Assistant (HAOS on 10.0.30.117) ships its journal with the Vector add-on
(github.com/twiebe/hassos-addons-vector, sink `victorialogs`) to
`https://logs.gvarph.com/insert/elasticsearch/` with basic auth user `ha-vector`
(`secrets/vl_push_htpasswd.age`; password in `~/.nixos-config/.env` as HA_VECTOR_VL_PASSWORD).
Stream fields are the journald names `host,CONTAINER_NAME`, the same shape fluent-bit gives nas1's
own journal. CrowdSec tails `{host="homeassistant",CONTAINER_NAME="homeassistant"}` back out of
VictoriaLogs (`source: victorialogs`) for the hub's home-assistant collection.
Local services stay on journalctl sources: no dependency on fluent-bit/VictoriaLogs being up.
HA must have `http.use_x_forwarded_for` with nas1 in `trusted_proxies`, or its ban log shows nas1's IP.

## Checks

```
sudo cscli bouncers list                  # crowdsec-nginx with a recent "Last API pull"
sudo cscli decisions add -i <lan ip> -d 5m -r test   # then curl any vhost from that client -> 403
sudo cscli decisions delete -i <lan ip>
```
