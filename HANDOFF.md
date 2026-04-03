# Handoff

## Purpose

This file captures the current working state of the Kerio Connect lab repository so work can resume quickly in another chat, shell, or host session.

## Current Snapshot

- Updated: 2026-04-03 16:09:31 UTC
- Repository: `/root/kerio-connect`
- Branch: `main`
- Base HEAD: `acc373c` - Add handoff and next steps docs
- Remote: `origin` - `git@github.com:foksk76/kerio-connect.git`
- Kerio image: `kerio-connect-kerio-connect:latest 998MB`
- Postfix service: `inactive`
- Host port 25: `busy: LISTEN 0      4096         0.0.0.0:25        0.0.0.0:*    users:(("docker-proxy",pid=25435,fd=4))`

## Compose Status

- `kerio-connect`: Up 17 minutes (healthy), health `healthy`

## Pending Change Areas

- Commit-time doc automation updated.
- Build and runtime configuration changed.
- Project documentation refreshed.

## Pending Source Files

- `.env.example`
- `.githooks/pre-commit`
- `Dockerfile`
- `README.md`
- `docker-compose.yml`
- `scripts/enable-git-hooks.sh`
- `scripts/update-commit-docs.sh`

## Pending Diffstat

 7 files changed, 418 insertions(+), 15 deletions(-)

```
 .env.example                  |  13 +-
 .githooks/pre-commit          |   6 +
 Dockerfile                    |  59 ++++++++-
 README.md                     |  47 +++++--
 docker-compose.yml            |   6 +-
 scripts/enable-git-hooks.sh   |   6 +
 scripts/update-commit-docs.sh | 296 ++++++++++++++++++++++++++++++++++++++++++
 7 files changed, 418 insertions(+), 15 deletions(-)
```

## Resume Notes

1. The build now auto-resolves the official Kerio Linux DEB from the public Kerio archive, with local `artifacts/` and explicit `KERIO_DOWNLOAD_URL` overrides still supported.
2. The current container was able to reach `cdn.kerio.com` and `appmanager.gfi.com`, and the image build completed successfully on this host.
3. The current runtime path still needs normal first-run verification inside Kerio Connect Administration after the initial wizard is completed.
4. Commit-time automation for `HANDOFF.md`, `NEXT_STEPS.md`, and `CHANGELOG.md` lives in `scripts/update-commit-docs.sh` and is triggered by `.githooks/pre-commit`.

## Suggested Resume Commands

```bash
cd /root/kerio-connect
git status
docker compose ps
docker compose logs --tail=200 kerio-connect
```

## Official Hosts

- https://cdn.kerio.com/
- https://appmanager.gfi.com/
- https://support.kerioconnect.gfi.com/
