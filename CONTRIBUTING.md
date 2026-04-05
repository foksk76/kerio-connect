# Contributing

Thanks for helping improve the Kerio Connect lab wrapper.

## Scope

This repository covers the Docker wrapper, scripts, CI workflow, and documentation around running the official Kerio Connect Linux package in a lab setting.

Changes that are in scope:

- Docker and Compose behavior
- persistence, first-run, and log-export workflow
- CI and release automation
- operator documentation and troubleshooting notes

Changes that are out of scope:

- redistribution of Kerio Connect vendor binaries
- reverse engineering or patching proprietary Kerio application code for general use
- production deployment guarantees

## Before You Change Anything

1. Read [README.md](README.md), especially the quick start, first-run, syslog, and limitation sections.
2. Enable local hooks once per clone:

```bash
scripts/enable-git-hooks.sh
```

3. If your change affects runtime behavior, validate it with the lab workflow:

```bash
docker compose build
docker compose up -d
docker compose ps
docker compose logs --tail=200 kerio-connect
```

## Contribution Guidelines

- Keep the repository ASCII-first unless a file already uses Unicode and there is a clear reason.
- Do not commit vendor installers, license keys, or other secrets.
- Prefer documented, reproducible workflows over one-off operator fixes.
- When editing docs, keep `README.md` focused on onboarding and move deep operational detail into dedicated files when needed.
- When editing release-facing behavior, update [CHANGELOG.md](CHANGELOG.md) with a short high-signal note.

## Pull Requests

Please include:

- what changed
- why it changed
- how you validated it
- any operator-visible impact

If a change was only tested locally, say that explicitly.

## Reporting Bugs

Open an issue and include:

- host OS and Docker / Compose version
- whether the build used auto-download, `artifacts/`, or `KERIO_DOWNLOAD_URL`
- relevant container logs
- whether first run had already been completed
- whether the problem is reproducible after `docker compose down` and `docker compose up -d`

## Security

For security-sensitive problems, do not open a public issue with secrets, exploit details, or mailbox contents. Follow [SECURITY.md](SECURITY.md) instead.
