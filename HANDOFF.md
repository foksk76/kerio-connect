# Handoff

## Purpose

This file captures the current working state of the Kerio Connect lab repository so work can resume quickly in another chat, shell, or host session.

## Current Snapshot

- Updated: 2026-04-07 14:16:34 UTC
- Repository: `/root/kerio-connect`
- Branch: `main`
- Base HEAD: `41be738` - Release v0.2.0
- Remote: `origin` - `git@github.com:foksk76/kerio-connect.git`
- Kerio image: `kerio-connect-kerio-connect:latest 1GB`
- Postfix service: `inactive`
- Host port 25: `busy: LISTEN 0      4096         0.0.0.0:25        0.0.0.0:*    users:(("docker-proxy",pid=448,fd=4))`

## Recorded Lab State

- First run: `completed`
- Admin account: `doge@kerio.lo`
- Primary domain: `kerio.lo`
- Hostname: `kerio.lo`
- Message store: `/opt/kerio/mailserver/store/`
- License note: `Built-in trial link points to the legacy kerio.com trial URL and currently returns HTTP 404; use the manual GFI Free Trial URL from README.md.`
- DNS note: `HomeLab DNS publishes kerio.lo as an internal A record only; no MX record is expected in this lab. External GFI hosts still resolve from inside the container, so the telemetry DNS warning is tracked separately.`
- Syslog note: `External Syslog is enabled for mail, operations, security, spam, and audit to elastic.lo:5514 with application name kerio.`

## Compose Status

- `kerio-connect`: Up 2 hours (healthy), health `healthy`

## Pending Change Areas

- Project documentation refreshed.

## Pending Source Files

- `CONTRIBUTING.md`
- `README.md`
- `README.ru.md`

## Pending Diffstat

 3 files changed, 666 insertions(+), 204 deletions(-)

```
 CONTRIBUTING.md |   2 +
 README.md       | 409 +++++++++++++++++++++++++-------------------------
 README.ru.md    | 459 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 666 insertions(+), 204 deletions(-)
```

## Resume Notes

1. The build now auto-resolves the official Kerio Linux DEB from the public Kerio archive, with local `artifacts/` and explicit `KERIO_DOWNLOAD_URL` overrides still supported.
2. The current container was able to reach `cdn.kerio.com` and `appmanager.gfi.com`, and the image build completed successfully on this host.
3. Runtime milestones recorded in `.lab-state.env` are folded into this handoff so first-run progress is not lost between chats or commits.
4. Commit-time automation for `HANDOFF.md` and `NEXT_STEPS.md` lives in `scripts/update-commit-docs.sh` and is triggered by `.githooks/pre-commit`.

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
