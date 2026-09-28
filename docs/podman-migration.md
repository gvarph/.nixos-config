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
- [ ] trek: one container, already hardened; maps 1:1 to quadlet keys
- [ ] monitoring/grafana (down) → native `services.grafana` with the provisioning dir
- [ ] music-assistant → native `services.music-assistant`; then close the 8000–65535 firewall hole

## 2. Easy (one wrinkle each)

- [ ] 9router: two containers, one named volume, loopback port
- [ ] hevy2garmin: `.build` unit from `~/hevy2garmin`; env file must stay `$`-free
- [ ] navidrome: `ND_EXTAUTH_TRUSTEDSOURCES` hardcodes two gateway IPs, must match the new network
- [ ] monitoring/logs: mounts `/var/log/journal`; native `services.victorialogs` + fluent-bit is one step further
- [ ] garage (down) → native `services.garage`, same `garage.toml`
- [ ] photon (down): decide if still wanted; container-wise trivial, 180 GB index on rpool/root

## 3. Medium (multi-container, a database, or a build from git)

- [ ] audiobookshelf: app + sidecar `.build` from a git URL at a pinned commit; state not a dataset
- [ ] shelfarr: static IP on servarr network, `AddHost=host.containers.internal`; needs the servarr `.network` first
- [ ] ble_scale_sync: `.build` from `~/ble-scale-sync` fork, custom entrypoint, writes its own config; check host BLE access needs
- [ ] sparkyfitness: 4 containers, Postgres 18, internal nginx with rate limiting; no module; state not a dataset
- [ ] paperless: 6 containers (Postgres 18, Redis, paperless-gpt, exporters); native `services.paperless` later via dump/restore
- [ ] geocoding-throttle: lives on dawarich's network, unhealthy today; migrate with dawarich or drop

## 4. Hard (devices, privileges, cross-stack networks)

- [ ] create the servarr `.network` unit (172.39.0.0/24) before jellyfin, shelfarr, arr
- [ ] jellyfin: 5 containers, `/dev/dri` + `render` group, two external networks with pinned IP, jellystat creds hardcoded in compose; native `services.jellyfin` is the cleaner end state
- [ ] immich: 7 containers; flatten the two `extends` hwaccel files, `/dev/dri`, `device_cgroup_rules` via `PodmanArgs`, replace autoheal with systemd `Restart=`; keep the custom Postgres 14 image (native later = riskiest data migration)
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
