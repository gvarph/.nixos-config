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
- [ ] monitoring/grafana (down) → native `services.grafana` with the provisioning dir
- [ ] music-assistant → native `services.music-assistant`; then close the 8000–65535 firewall hole

## 2. Easy (one wrinkle each)

- [x] 9router (2026-09-28, `devices/nas1/9router.nix`): first quadlet network + named volume + container dependency; images pinned (headroom by digest); dashboard password is INITIAL_PASSWORD until changed in-app
- [x] hevy2garmin (2026-09-28, `devices/nas1/hevy2garmin.nix`): `.build` from the pinned upstream commit via fetchGit, so `~/hevy2garmin` is no longer needed; docker.io added as search registry for upstream Dockerfiles; podman needs an explicit HealthCmd for `Notify=healthy`
- [x] navidrome → native `services.navidrome` (2026-09-28, `devices/nas1/navidrome.nix`); new dataset rpool/flash/navidrome; SSO header trusted from loopback only; library path re-synced from MusicFolder on first start
- [x] monitoring/logs → native `services.victorialogs` + `services.fluent-bit` (2026-09-28, `devices/nas1/logs.nix`); dataset rpool/flash/victorialogs without snapshots (excluded from sanoid, syncoid, restic); loopback only; MCP server uses host networking
- [x] garage: removed 2026-09-28 (was down; vhost, dataset and stack deleted)
- [x] photon: removed 2026-09-28 (was down; index dir already gone)

## 3. Medium (multi-container, a database, or a build from git)

- [x] audiobookshelf (2026-09-28, `devices/nas1/audiobookshelf.nix`): upstream image pinned, runs as 1000:100 (shares the media tree, so no userns); WatchShelf sidecar built from the pinned commit; new dataset rpool/flash/audiobookshelf; root-owned leftovers needed a chown
- [ ] shelfarr: static IP on servarr network, `AddHost=host.containers.internal`; needs the servarr `.network` first
- [ ] ble_scale_sync: `.build` from `~/ble-scale-sync` fork, custom entrypoint, writes its own config; check host BLE access needs
- [x] sparkyfitness (2026-09-28, `devices/nas1/sparkyfitness.nix`): 3 quadlets on a private network (exporter dropped), images pinned v1.7.3, POSTGRES_* split into its own secret; new dataset rpool/flash/sparkyfitness
- [x] paperless (2026-09-28, `devices/nas1/paperless.nix`): 4 quadlets on a private network (exporters dropped), images pinned; paperless-gpt joins the 9router network and uses `ds/deepseek-v4.1-flash` via 9router; its entrypoint needs `userns=auto:size=65536`
- [ ] geocoding-throttle: lives on dawarich's network, unhealthy today; migrate with dawarich or drop

## 4. Hard (devices, privileges, cross-stack networks)

- [ ] create the servarr `.network` unit (172.39.0.0/24) before jellyfin, shelfarr, arr
- [x] jellyfin + jellystat (2026-09-28, `devices/nas1/jellyfin.nix`): `/dev/dri` via AddDevice + GroupAdd render/video, runs as 1000:100, QSV verified with vainfo (iHD, H264/HEVC VLD+EncSlice); 8096 loopback only, discovery port dropped; jellystat creds moved to agenix, new vhost jellystat.gvarph.com behind oauth2-proxy
- [ ] jellyseerr: still in `docker_storage/jellyfin` compose (pinned 172.39.0.10 on servarrnetwork); migrate with arr
- [x] immich (2026-09-28, `devices/nas1/immich.nix`): 4 quadlets (autoheal + exporters dropped; `HealthOnFailure=kill` + Restart replaces autoheal), pinned v3.2.2, custom Postgres 14 image kept, `/dev/dri` for QSV (verified with an in-container h264_qsv encode) and OpenVINO, USB passthrough dropped; 2283 loopback only; app deps are `Wants` not `Requires` after a transient registry pull failure cancelled the server's start
- [ ] dawarich (down): decide if it comes back; PostGIS, `shm_size 1G`, health-gated deps, owns a network; native `services.dawarich` exists
- [ ] arr: gluetun + plain qBittorrent with `Network=gluetun.container` (PIA port forward via `VPN_PORT_FORWARDING_UP_COMMAND`), keep 172.39.0.2 on gluetun, fix qbit-manager URL (no more 172.17.0.1), `.build` for qbit-manager, 11 mechanical conversions; do last

## 5. Redesign, not migration

- [ ] monitoring/metrics (off, resource cost): if it returns, native `services.vmagent` with static targets, node_exporter cgroup collectors, cadvisor only with slow housekeeping and reduced metric sets

## Cross-cutting

- [ ] Backup blind spot: `/flash/{audiobookshelf,ntfy,navidrome,shelfarr,sparkyfitness,metrics,logs}` are plain dirs on rpool/root, not datasets → not snapshotted, not in restic. Docker named volumes likewise.
- [ ] Every unit that touches `/flash/*` or `/tank`: `After=zfs-mount.service` + `ConditionPathIsMountPoint=`; Podman refuses missing bind sources, so a failed pool import fails loudly instead of writing into rpool/root
- [ ] Rootful podman storage stays on rpool/root (`/var/lib/containers`), never under `/home` (restic would back up image layers)
- [ ] Remove `virtualisation.docker` and the image-prune timer once the last stack is gone
- [ ] Delete the stale `arr/docker-compose.nix` (compose2nix leftover with a plaintext PIA password)

Suggested order: group 1 → servarr network → shelfarr → audiobookshelf → paperless → sparkyfitness → jellyfin → immich → arr. Decide the fate of dawarich, photon, geocoding-throttle and metrics before touching them.
