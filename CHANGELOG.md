# Changelog

All notable changes to this lab repository are tracked here.

## Unreleased

### Current Commit Snapshot

- Updated: 2026-04-04 08:23:00 UTC
- Branch: `main`
- Base HEAD: `8f3a95b`
- Remote: `origin`

### Change Areas

- Commit-time doc automation updated.
- Build and runtime configuration changed.
- Project documentation refreshed.

### Source Files In This Commit

- `.env.example`
- `.lab-state.env`
- `Dockerfile`
- `README.md`
- `docker-compose.yml`
- `scripts/configure-log-root.sh`
- `scripts/entrypoint.sh`
- `scripts/seed-state.sh`
- `scripts/update-commit-docs.sh`

### Diffstat

-  9 files changed, 112 insertions(+), 17 deletions(-)

```
 .env.example                  |  1 +
 .lab-state.env                |  7 +++++
 Dockerfile                    |  9 +++++-
 README.md                     | 27 ++++++++++++++++--
 docker-compose.yml            |  3 ++
 scripts/configure-log-root.sh | 13 +++++----
 scripts/entrypoint.sh         |  1 -
 scripts/seed-state.sh         |  4 +--
 scripts/update-commit-docs.sh | 64 +++++++++++++++++++++++++++++++++++++++----
 9 files changed, 112 insertions(+), 17 deletions(-)
```

### Baseline

- Debian 13 Kerio Connect lab scaffold.
- Docker Compose wrapper, runtime scripts, and healthcheck.
- README with VM requirements, first-run flow, Syslog notes, and commit-time doc automation.
