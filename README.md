# Kerio Connect Lab

This repository wraps the official Kerio Connect Debian installer in a local Docker lab for evaluation and integration work. The vendor documents Linux `.deb` and `.rpm` installs plus virtual appliances, but does not publish an official Docker deployment model, so treat this repository as a local lab wrapper rather than a production reference.

## What This Repository Does

- Builds an image from the official Kerio Connect Debian installer.
- Runs Kerio Connect on Debian 13 inside Docker.
- Keeps binaries in the image while persisting configuration, message store, and logs in Docker volumes.
- Exposes the first-run administration interface on `https://localhost:4040/admin`.
- Prepares logs for export to an external Syslog target such as the Logstash stack in the neighboring project.

## VM Requirements

Vendor minimums for `1-20` users are:

- `2 Core CPU 1 GHz 64-bit`
- `4 GB RAM`
- `40 GB` free space for the message store and backup

GFI also lists `Debian 13 (Trixie)` as a supported Linux platform and notes that virtual deployments should use the same requirements as standard installs plus host OS overhead.

Official references:

- https://support.kerioconnect.gfi.com/article/112061-kerio-connect-server-system-installation-requirements
- https://support.gfi.com/article/110673-kerio-connect-server-system-requirements

Practical lab recommendation:

- `4 vCPU`
- `8 GB RAM`
- `60 GB` disk

The vendor minimum is enough to start small lab instances, but the higher recommendation is less painful once indexing, logging, and browser-based setup are all active.

## What You Need Before Build

1. Create a local `.env` from [`.env.example`](.env.example) if you want to override ports, limits, or volume names.
2. Choose how the build should get the official Kerio Connect Debian installer:
   - leave `KERIO_AUTO_DOWNLOAD=1` to resolve the latest public Linux DEB from the official Kerio archive automatically
   - or place a `.deb` file in [`artifacts/`](artifacts/) for an offline or pinned build
   - or set `KERIO_DOWNLOAD_URL` to an explicit official Linux DEB URL
3. If you need reproducibility, set `KERIO_VERSION_LABEL` and optionally `KERIO_DOWNLOAD_SHA256`.

Official installer guidance:

- https://support.kerioconnect.gfi.com/article/112195-installing-kerio-connect-server-on-linux-debian-ubuntu
- https://cdn.kerio.com/archive/index.php?type=source

## Official Download Hosts

Use the official vendor hosts below for generic download entry points and installer retrieval. These are intentionally host-level links, without version-pinned paths:

- https://cdn.kerio.com/
- https://appmanager.gfi.com/
- https://support.kerioconnect.gfi.com/

## Repository Layout

- [`Dockerfile`](Dockerfile): Debian 13 image plus Kerio install wrapper with official-archive auto-download and local artifact fallback.
- [`docker-compose.yml`](docker-compose.yml): local lab runtime with volumes, ports, and healthcheck.
- [`.githooks/pre-commit`](.githooks/pre-commit): auto-refreshes `HANDOFF.md`, `NEXT_STEPS.md`, and `CHANGELOG.md` before each commit.
- [`scripts/entrypoint.sh`](scripts/entrypoint.sh): container start logic.
- [`scripts/seed-state.sh`](scripts/seed-state.sh): persists config and store paths without covering the whole install tree.
- [`scripts/configure-log-root.sh`](scripts/configure-log-root.sh): best-effort log-root patch for `mailserver.cfg`.
- [`scripts/healthcheck.sh`](scripts/healthcheck.sh): probes the admin endpoint or service status.
- [`scripts/update-commit-docs.sh`](scripts/update-commit-docs.sh): generates commit-time snapshots for `HANDOFF.md`, `NEXT_STEPS.md`, and `CHANGELOG.md`.
- [`scripts/enable-git-hooks.sh`](scripts/enable-git-hooks.sh): configures `core.hooksPath=.githooks` for the local clone.
- [`CHANGELOG.md`](CHANGELOG.md): local project history.

## Quick Start

1. Review [`.env.example`](.env.example) and create `.env` if needed.
2. Decide whether to:
   - use automatic download from the official Kerio archive
   - pin a specific archive version through `KERIO_VERSION_LABEL`
   - override the exact official DEB URL through `KERIO_DOWNLOAD_URL`
   - or place a local `.deb` in [`artifacts/`](artifacts/)
3. If the host already runs a local MTA on port `25`, stop it before starting the lab. On this Debian host the conflicting service was `postfix`:

```bash
systemctl stop postfix
ss -ltnp '( sport = :25 )'
```

4. Build the image:

```bash
docker compose build
```

5. Start the lab:

```bash
docker compose up -d
```

6. Open `https://localhost:4040/admin`.

## Official First-Run Scenario

Follow the vendor wizard after the container is up:

1. Open `https://kerio_connect_server:4040/admin`.
2. Choose the UI language.
3. Accept the license agreement.
4. Set the internet hostname and primary email domain.
5. Create the administrator account.
6. Choose the message store directory.
7. Register the product or continue unregistered.

Official references:

- https://support.gfi.com/article/110739-initial-configuration-of-kerio-connect-after-installation
- https://manuals.gfi.com/en/kerio/connect/content/installation-and-upgrade/performing-initial-configuration-in-kerio-connect-1567.html
- https://manuals.gfi.com/en/kerio/connect/content/server-configuration/accessing-kerio-connect-administration-1161.html

## Official Syslog Scenario

After the first-run wizard, enable external logging in Kerio Connect Administration:

1. Go to `Logs`.
2. Open the log type you want to export.
3. Right-click and choose `Log Settings`.
4. Open the `External Logging` tab.
5. Enable Syslog logging.
6. Set the Syslog server as `<host>:<port>` if you need a custom port.

For the neighboring Logstash project, the natural target is:

- host: `host.docker.internal`
- port: `5514`

Official references:

- https://support.kerioconnect.gfi.com/article/114245-syslog-logging-in-kerio-connect
- https://support.kerioconnect.gfi.com/en-us/article/114385-configuring-log-settings-in-kerio-connect
- https://manuals.gfi.com/en/kerio/connect/content/server-configuration/managing-logs-in-kerio-connect-1126.html

## Log Path Notes

GFI documents the default Linux log path as `/opt/kerio/mailserver/store/logs`. GFI also documents the `LogGlobal -> RelativePathsRoot` variable in `mailserver.cfg` as the path to the log files. That means a move to `/opt/kerio/logs` is supported in principle through configuration.

Official references:

- https://manuals.gfi.com/en/kerio/connect/content/server-configuration/managing-logs-in-kerio-connect-1126.html
- https://support.kerioconnect.gfi.com/en-us/article/114340-editing-kerio-connect-configurations-to-use-the-correct-system-paths
- https://support.kerioconnect.gfi.com/article/114788-modifying-the-mailserver-cfg

This repository does two things:

- It attempts a best-effort `mailserver.cfg` update through [`scripts/configure-log-root.sh`](scripts/configure-log-root.sh).
- It also creates a compatibility symlink from the default `store/logs` location to `${KERIO_LOG_ROOT}` so the lab still works if the XML layout differs from what the helper script expects.

## Smoke Checks

Use these commands after startup:

```bash
docker compose ps
docker compose logs --tail=200 kerio-connect
curl -k https://localhost:4040/admin
```

Then verify:

- the container stays `healthy`
- `https://localhost:4040/admin` responds
- the first-run wizard or admin login page opens
- the configured log types appear on the remote Syslog receiver

## Limitations

- This repository does not ship the Kerio installer; builds either download the official Linux DEB from the public Kerio archive or use a local `.deb` that you provide.
- The runtime model is a lab wrapper around the Linux package, not an officially documented Docker deployment.
- The `mailserver.cfg` XML schema is not documented in detail by GFI, so automatic log-root patching is intentionally conservative.
- Automatic download depends on the current Kerio archive HTML structure and CDN availability, so local artifacts or pinned URLs are still the safer choice for reproducible builds.
- Production use should prefer the vendor-supported Linux or virtual-appliance installation paths.
