# Docker → Podman quadlet migration (nas1)

Target: rootful quadlet-nix with `UserNS=auto`, stacks converted one at a time.
Where a native NixOS module is the better end state it is noted; those can skip the
container step. Inventory as of 2026-09-28: 24 stacks, 18 running.

Before any stack: pin its image tags, move its `.env` into agenix, make its state dir
a `rpool/flash` child dataset if it is not one (see "Backup blind spot" below).

## 0. Housekeeping (no migration)

- [ ] pocket-id: delete compose dir and the stale `pocket-id_default` network (already native)
- [ ] nextcloud: run `zfs destroy -r rpool/flash/nextcloud` and `tank/snapshots/flash/nextcloud`, remove the docker volume/images, commit the sanoid change

## 1. Trivial (single container, config bind, no coupling)

- [x] cloudflare_ddns → native `services.cloudflare-ddns` (2026-09-28, `devices/nas1/ddns.nix`, reuses the ACME token)
- [x] ntfy → native `services.ntfy-sh` (2026-09-28, `devices/nas1/ntfy.nix`; dataset rpool/flash/ntfy mounted at the DynamicUser state path, JSON logs feed crowdsec)
- [x] obsidian (CouchDB): removed 2026-09-28, never used beyond a day
- [x] trek: first quadlet (2026-09-28, `devices/nas1/trek.nix`); established `podman.nix` (quadlet-nix, `userns=auto` pool), agenix env files with inline comments stripped, `:U` volumes, loopback-only ports, ZFS mount guard
- [x] monitoring/grafana → native `services.grafana` (2026-09-28, `devices/nas1/grafana.nix`): datasources, dashboards (`devices/nas1/grafana/dashboards/`), ntfy contact point, policies and rules provisioned from Nix; ntfy token and a new secret_key via agenix (`$__file{}`); dataset rpool/flash/grafana at /var/lib/grafana; crowdsec reads grafana.service from the journal
- [x] music-assistant → native `services.music-assistant` (2026-09-28, `devices/nas1/music-assistant.nix`, nixpkgs tracks upstream within days); dataset re-homed to the DynamicUser path; 8000–65535 firewall range replaced by an explicit list (module ports + 8095 for HA + sonarr/prowlarr/slskd until arr migrates)

## 2. Easy (one wrinkle each)

- [x] 9router (2026-09-28, `devices/nas1/9router.nix`): first quadlet network + named volume + container dependency; images pinned; headroom sidecar removed 2026-10-03; dashboard password is INITIAL_PASSWORD until changed in-app
- [x] hevy2garmin (2026-09-28, `devices/nas1/hevy2garmin.nix`): `.build` from the pinned upstream commit via fetchGit, so `~/hevy2garmin` is no longer needed; docker.io added as search registry for upstream Dockerfiles; podman needs an explicit HealthCmd for `Notify=healthy`
- [x] navidrome → native `services.navidrome` (2026-09-28, `devices/nas1/navidrome.nix`); new dataset rpool/flash/navidrome; SSO header trusted from loopback only; library path re-synced from MusicFolder on first start
- [x] monitoring/logs → native `services.victorialogs` + `services.fluent-bit` (2026-09-28, `devices/nas1/logs.nix`); dataset rpool/flash/victorialogs without snapshots (excluded from sanoid, syncoid, restic); loopback only; MCP server uses host networking
- [x] garage: removed 2026-09-28 (was down; vhost, dataset and stack deleted)
- [x] photon: removed 2026-09-28 (was down; index dir already gone)

## 3. Medium (multi-container, a database, or a build from git)

- [x] audiobookshelf (2026-09-28, `devices/nas1/audiobookshelf.nix`): upstream image pinned, runs as 1000:100 (shares the media tree, so no userns); WatchShelf sidecar built from the pinned commit; new dataset rpool/flash/audiobookshelf; root-owned leftovers needed a chown
- [x] ble_scale_sync (2026-09-28, `devices/nas1/ble-scale-sync.nix`): upstream image 1.29.0 (both fork PRs shipped since 1.27.0), entrypoint override kept to skip the BT reset and pass --config, secrets via agenix (config.yaml only has `${VAR}` placeholders), state on rpool/flash/ble-scale-sync; `~/ble-scale-sync` no longer needed
- [x] sparkyfitness (2026-09-28, `devices/nas1/sparkyfitness.nix`): 3 quadlets on a private network (exporter dropped), images pinned v1.7.3, POSTGRES_* split into its own secret; new dataset rpool/flash/sparkyfitness
- [x] paperless (2026-09-28, `devices/nas1/paperless.nix`): 4 quadlets on a private network (exporters dropped), images pinned; paperless-gpt joins the 9router network and uses `ds/deepseek-v4.1-flash` via 9router; its entrypoint needs `userns=auto:size=65536`
- [x] geocoding-throttle: folded into `devices/nas1/dawarich.nix` (nginx config from the nix store; health probe on 127.0.0.1 since busybox wget prefers ::1)

## 4. Hard (devices, privileges, cross-stack networks)

- [x] servarr `.network` (172.39.0.0/24, same pinned IPs and container names as compose, so no app DB edits) — 2026-09-28, `devices/nas1/arr.nix`
- [x] jellyfin + jellystat (2026-09-28, `devices/nas1/jellyfin.nix`): `/dev/dri` via AddDevice + GroupAdd render/video, runs as 1000:100, QSV verified with vainfo (iHD, H264/HEVC VLD+EncSlice); 8096 loopback only, discovery port dropped; jellystat creds moved to agenix, new vhost jellystat.gvarph.com behind oauth2-proxy
- [ ] jellyseerr: still in `docker_storage/jellyfin` compose (pinned 172.39.0.10 on servarrnetwork); migrate with arr
- [x] immich (2026-09-28, `devices/nas1/immich.nix`): 4 quadlets (autoheal + exporters dropped; `HealthOnFailure=kill` + Restart replaces autoheal), pinned v3.2.2, custom Postgres 14 image kept, `/dev/dri` for QSV (verified with an in-container h264_qsv encode) and OpenVINO, USB passthrough dropped; 2283 loopback only; app deps are `Wants` not `Requires` after a transient registry pull failure cancelled the server's start
- [x] dawarich (2026-09-28, `devices/nas1/dawarich.nix`): 5 quadlets (exporters dropped), pinned 1.15.2, migrations applied on the existing PostGIS data, tested end to end; **import commented out in default.nix on purpose**, re-enable to bring it back
- [x] arr (2026-09-28, `devices/nas1/arr.nix`): binhex qbittorrentvpn kept, unprivileged (NET_ADMIN + src_valid_mark sysctl + /dev/net/tun; gluetun has no native PIA WireGuard), qbit-manager built from `devices/nas1/qbit-manager/` and talking to `qbittorrent:8080`, lscr apps via a shared helper, images pinned; sonarr/radarr/prowlarr/bazarr vhosts behind oauth2-proxy, 8989/9696 out of the firewall
- [x] jellyseerr (2026-09-28, `devices/nas1/jellyseerr.nix`): also on the jellyfin network so `jellyfin` resolves again; per-network `:ip=` since it joins two networks
- [ ] slskd through its own VPN (built 2026-09-28, **off** via `slskdVpn = false` in `devices/nas1/arr.nix`, slskd itself is off with it): binhex privoxyvpn container holds 172.39.0.16 and slskd shares its netns; inbound peers use PIA's forwarded port, pushed into slskd by the `slskd-port-sync` timer via its API; 50300 closed on the host. Blocked on PIA: `www.privateinternetaccess.com/gtoken/generateToken` returns a Cloudflare 504 after 60s (for everyone, verified from the host) while `piaproxy.net` works, and binhex's `pia_generate_token` returns on the first URL's failure without trying the fallback. Retry when PIA recovers (`curl -s -m 70 -u x:y https://www.privateinternetaccess.com/gtoken/generateToken` should say `authentication failed` instantly); the same failure would hit qbittorrent on its next restart. Fallback option: share the qbittorrent tunnel instead (`Network=container:qbittorrent`, `VPN_INPUT_PORTS=5030`), at the cost of no inbound Soulseek port
- [x] shelfarr (2026-09-28, `devices/nas1/shelfarr.nix`): new dataset rpool/flash/shelfarr; joins servarr + audiobookshelf networks (ABS URL → `http://audiobookshelf:13378` in its settings); needs `ip_unprivileged_port_start=0` to bind :80 as PUID (docker set that by default)

## 5. Redesign, not migration

- [x] monitoring/metrics → native (2026-09-28, `devices/nas1/metrics.nix`): victoriametrics (dataset at the DynamicUser path, excluded from sanoid/syncoid/restic like victorialogs), vmagent with static loopback targets (job/instance keep the old container names), node + smartctl exporters, cadvisor in raw cgroup mode on `/system.slice/` (its podman factory can't read quadlet's split cgroups) with 30s housekeeping and `cpu,memory,network,oom_event` only, vmagent derives `name`/`unit` labels from the cgroup id; old VM data (last written 2026-08-31, 1-month retention) not carried over

## Cross-cutting

- [x] Backup blind spot: every remaining state dir is a dataset now; `/flash/metrics` and `/flash/logs` are leftovers to delete
- [ ] Every unit that touches `/flash/*` or `/tank`: `After=zfs-mount.service` + `ConditionPathIsMountPoint=`; Podman refuses missing bind sources, so a failed pool import fails loudly instead of writing into rpool/root
- [ ] Rootful podman storage stays on rpool/root (`/var/lib/containers`), never under `/home` (restic would back up image layers)
- [ ] Remove `virtualisation.docker` and the image-prune timer once the last stack is gone
- [ ] Delete the stale `arr/docker-compose.nix` (compose2nix leftover with a plaintext PIA password)

Suggested order: group 1 → servarr network → shelfarr → audiobookshelf → paperless → sparkyfitness → jellyfin → immich → arr. Decide the fate of dawarich, photon, geocoding-throttle and metrics before touching them.
