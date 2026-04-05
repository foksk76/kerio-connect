# Handoff

## Purpose

This file captures the current working state of the Kerio Connect lab repository so work can resume quickly in another chat, shell, or host session.

## Current Snapshot

- Updated: 2026-04-05 01:52:52 UTC
- Repository: `/root/kerio-connect`
- Branch: `main`
- Base HEAD: `1b568e3` - Fix CI smoke check on GitHub runners
- Remote: `origin` - `git@github.com:foksk76/kerio-connect.git`
- Kerio image: `kerio-connect-kerio-connect:latest 1GB`
- Postfix service: `inactive`
- Host port 25: `busy: LISTEN 0      4096         0.0.0.0:25        0.0.0.0:*    users:(("docker-proxy",pid=449,fd=4))`

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

- `kerio-connect`: Up About an hour (healthy), health `healthy`

## Pending Change Areas

- Project documentation refreshed.

## Pending Source Files

- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/pull_request_template.md`
- `.github/release.yml`
- `CHANGELOG.md`
- `CODE_OF_CONDUCT.md`
- `CONTRIBUTING.md`
- `README.md`
- `SECURITY.md`
- `SUPPORT.md`

## Pending Diffstat

 11 files changed, 389 insertions(+)

```
 .github/ISSUE_TEMPLATE/bug_report.yml      | 59 +++++++++++++++++++++++++
 .github/ISSUE_TEMPLATE/config.yml          |  8 ++++
 .github/ISSUE_TEMPLATE/feature_request.yml | 34 ++++++++++++++
 .github/pull_request_template.md           | 19 ++++++++
 .github/release.yml                        | 23 ++++++++++
 CHANGELOG.md                               | 29 ++++++++++++
 CODE_OF_CONDUCT.md                         | 31 +++++++++++++
 CONTRIBUTING.md                            | 71 ++++++++++++++++++++++++++++++
 README.md                                  | 35 +++++++++++++++
 SECURITY.md                                | 37 ++++++++++++++++
 SUPPORT.md                                 | 43 ++++++++++++++++++
 11 files changed, 389 insertions(+)
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
