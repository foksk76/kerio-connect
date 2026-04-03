# Handoff

## Purpose

This file captures the current state of the Kerio Connect lab repository so work can continue cleanly in another chat or on another SSH host.

## Current Status

- A new local repository was created at [`/root/kerio-connect-lab`](/root/kerio-connect-lab).
- `git` was initialized and the branch was renamed to `main`.
- The earlier ELK test stack in [`/root/kerio-logstash-project`](/root/kerio-logstash-project) was shut down before switching focus.
- No Kerio image build was run yet because the official Kerio Connect Debian installer is still missing from `artifacts/`.
- The user later said the project was moved to remote SSH host `10.4.29.71` at `/root/kerio-connect`, but this session did not have that path mounted yet.

## Decisions Already Made

- Target packaging model: local Docker lab wrapper around the official Kerio Connect Linux installer.
- Target distro inside the image: `Debian 13`.
- Repository should include `README`, `CHANGELOG`, Docker assets, helper scripts, and an artifact drop folder.
- `README` must include:
  - VM requirements
  - official first-run scenario
  - official Syslog scenario as the next step after first-run
- Log path goal: move logs away from the default Kerio path to `/opt/kerio/logs`.
- Because the exact `mailserver.cfg` XML structure is not fully documented, the implementation uses:
  - a best-effort XML update
  - a symlink fallback from the default Kerio logs location

## What Was Created

- [`.env.example`](/root/kerio-connect-lab/.env.example)
- [`.gitignore`](/root/kerio-connect-lab/.gitignore)
- [`CHANGELOG.md`](/root/kerio-connect-lab/CHANGELOG.md)
- [`Dockerfile`](/root/kerio-connect-lab/Dockerfile)
- [`docker-compose.yml`](/root/kerio-connect-lab/docker-compose.yml)
- [`README.md`](/root/kerio-connect-lab/README.md)
- [`HANDOFF.md`](/root/kerio-connect-lab/HANDOFF.md)
- [`artifacts/.gitignore`](/root/kerio-connect-lab/artifacts/.gitignore)
- [`scripts/entrypoint.sh`](/root/kerio-connect-lab/scripts/entrypoint.sh)
- [`scripts/healthcheck.sh`](/root/kerio-connect-lab/scripts/healthcheck.sh)
- [`scripts/seed-state.sh`](/root/kerio-connect-lab/scripts/seed-state.sh)
- [`scripts/configure-log-root.sh`](/root/kerio-connect-lab/scripts/configure-log-root.sh)

## What The Files Do

- [`Dockerfile`](/root/kerio-connect-lab/Dockerfile)
  Builds from `debian:13`, expects the official Kerio `.deb` in `artifacts/`, installs helper packages, then installs Kerio Connect.

- [`docker-compose.yml`](/root/kerio-connect-lab/docker-compose.yml)
  Runs one `kerio-connect` service with exposed admin and mail ports, named volumes, memory/CPU limits, and a healthcheck.

- [`scripts/entrypoint.sh`](/root/kerio-connect-lab/scripts/entrypoint.sh)
  Seeds persistent state, tries to re-point the log root, starts Kerio through `/etc/init.d/kerio-connect`, and keeps the container alive while the service is up.

- [`scripts/seed-state.sh`](/root/kerio-connect-lab/scripts/seed-state.sh)
  Persists config files, license directory, and message store without hiding the whole installed Kerio tree behind a volume.

- [`scripts/configure-log-root.sh`](/root/kerio-connect-lab/scripts/configure-log-root.sh)
  Uses `xmlstarlet` to try to patch `LogGlobal -> RelativePathsRoot` in `mailserver.cfg`.

- [`scripts/healthcheck.sh`](/root/kerio-connect-lab/scripts/healthcheck.sh)
  Probes the admin HTTPS endpoint and falls back to service status.

- [`README.md`](/root/kerio-connect-lab/README.md)
  Documents the lab goal, VM requirements, build/start steps, official first-run flow, official Syslog flow, log-path notes, and limitations.

## Validation Already Done

- `bash -n` passed for all scripts.
- `docker compose config` passed for the repository.
- The repository layout exists and is internally consistent.

## Important Assumptions

- The Kerio package on Debian 13 still provides `/etc/init.d/kerio-connect`.
- The package installs into `/opt/kerio/mailserver`.
- `mailserver.cfg` exists at `/opt/kerio/mailserver/mailserver.cfg`.
- The documented `RelativePathsRoot` field is still the right place to influence Kerio log storage.

These are reasonable assumptions from the vendor docs, but they still need to be verified against the actual installed package.

## Known Risks / Follow-Up Items

1. GFI documents Linux package installs and virtual appliances, but not Docker as an official deployment model.
2. The Kerio `.deb` may have additional runtime dependencies not discovered until the first build.
3. The exact XML shape in `mailserver.cfg` may differ from the helper script's assumptions.
4. The init script name or service control path may differ on the real package version.
5. `host.docker.internal` may not resolve on all Linux Docker hosts; Syslog targeting may need `extra_hosts`, a bridge IP, or a real network address.
6. Volume layout may need adjustment after the first successful install if Kerio writes to more directories than currently expected.

## Next Steps On The New Host

When work resumes on `10.4.29.71:/root/kerio-connect`:

1. Copy or recreate this repository at `/root/kerio-connect`.
2. Put the official Kerio Connect Debian installer into `artifacts/`.
3. Create `.env` from [`.env.example`](/root/kerio-connect-lab/.env.example) if port or resource overrides are needed.
4. Run:

```bash
docker compose build
docker compose up -d
```

5. Verify whether `/etc/init.d/kerio-connect` actually exists inside the built image.
6. Verify where the package really places:
   - `mailserver.cfg`
   - `users.cfg`
   - `license/`
   - `store/`
   - default logs
7. If needed, adjust [`scripts/seed-state.sh`](/root/kerio-connect-lab/scripts/seed-state.sh) and [`scripts/configure-log-root.sh`](/root/kerio-connect-lab/scripts/configure-log-root.sh) to match the real package layout.
8. Open `https://<host>:4040/admin` and complete the official first-run wizard.
9. In Kerio Connect Administration, enable external Syslog logging and point it at the Logstash receiver.
10. Validate that syslog messages arrive in the neighboring Logstash stack.

## Suggested First Commands On The New Host

```bash
cd /root/kerio-connect
git status
ls -la
ls -la artifacts
docker compose build
docker compose up -d
docker compose logs --tail=200
```

## Official Sources Used

- Kerio Connect system requirements:
  - https://support.kerioconnect.gfi.com/article/112061-kerio-connect-server-system-installation-requirements
  - https://support.gfi.com/article/110673-kerio-connect-server-system-requirements

- Installing on Debian/Ubuntu:
  - https://support.kerioconnect.gfi.com/article/112195-installing-kerio-connect-server-on-linux-debian-ubuntu

- First-run configuration:
  - https://support.gfi.com/article/110739-initial-configuration-of-kerio-connect-after-installation
  - https://manuals.gfi.com/en/kerio/connect/content/installation-and-upgrade/performing-initial-configuration-in-kerio-connect-1567.html

- Admin access / remote admin ports:
  - https://manuals.gfi.com/en/kerio/connect/content/server-configuration/accessing-kerio-connect-administration-1161.html
  - https://manuals.gfi.com/en/kerio/connect/content/server-configuration/administration/what-ports-are-used-by-kerio-connect-for-remote-administration-442.html

- Syslog and log settings:
  - https://support.kerioconnect.gfi.com/article/114245-syslog-logging-in-kerio-connect
  - https://support.kerioconnect.gfi.com/en-us/article/114385-configuring-log-settings-in-kerio-connect
  - https://manuals.gfi.com/en/kerio/connect/content/server-configuration/managing-logs-in-kerio-connect-1126.html

- Editing system paths and `mailserver.cfg`:
  - https://support.kerioconnect.gfi.com/en-us/article/114340-editing-kerio-connect-configurations-to-use-the-correct-system-paths
  - https://support.kerioconnect.gfi.com/article/114788-modifying-the-mailserver-cfg
