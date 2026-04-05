# Support

This repository is a lab wrapper around the official Kerio Connect Linux package. Support is therefore split between repository-wrapper problems and vendor-product problems.

## Use This Repository For

- Docker build failures in this repo
- Compose runtime issues in this repo
- persistence, first-run, logging, CI, and documentation problems
- questions about how this lab is intended to be used

## Do Not Expect This Repository To Provide

- official GFI / Kerio product support
- commercial licensing assistance from the repository maintainer
- production architecture guidance
- redistribution of vendor installers or license material

## Best Way To Ask For Help

Open a GitHub issue and include:

- what you expected
- what actually happened
- host OS, Docker version, and Docker Compose version
- whether you used auto-download, `artifacts/`, or an explicit `KERIO_DOWNLOAD_URL`
- the relevant output from `docker compose ps` and `docker compose logs --tail=200 kerio-connect`

## Before Opening An Issue

Try these checks first:

```bash
docker compose ps
docker compose logs --tail=200 kerio-connect
curl -k https://localhost:4040/admin
```

Then compare what you see with [README.md](README.md), [HANDOFF.md](HANDOFF.md), and [NEXT_STEPS.md](NEXT_STEPS.md).

## Security-Sensitive Problems

If the report involves credentials, mailbox data, private infrastructure details, or an exploitable condition, use [SECURITY.md](SECURITY.md) instead of a normal public issue.
