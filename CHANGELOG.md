# Changelog

All notable changes to this lab repository are tracked here.

## Unreleased

### Current Commit Snapshot

- Updated: 2026-04-03 16:09:31 UTC
- Branch: `main`
- Base HEAD: `acc373c`
- Remote: `origin`

### Change Areas

- Commit-time doc automation updated.
- Build and runtime configuration changed.
- Project documentation refreshed.

### Source Files In This Commit

- `.env.example`
- `.githooks/pre-commit`
- `Dockerfile`
- `README.md`
- `docker-compose.yml`
- `scripts/enable-git-hooks.sh`
- `scripts/update-commit-docs.sh`

### Diffstat

-  7 files changed, 418 insertions(+), 15 deletions(-)

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

### Baseline

- Debian 13 Kerio Connect lab scaffold.
- Docker Compose wrapper, runtime scripts, and healthcheck.
- README with VM requirements, first-run flow, Syslog notes, and commit-time doc automation.
