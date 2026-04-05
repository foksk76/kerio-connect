# Kerio Connect Lab

Reproducible Docker-based lab environment for Kerio Connect on Debian 13.

[![Docker Lab CI](https://github.com/foksk76/kerio-connect/actions/workflows/docker-image.yml/badge.svg)](https://github.com/foksk76/kerio-connect/actions/workflows/docker-image.yml)

> **Project status:** Educational / lab / reproducible project. Use it for evaluation, debugging, integration tests, and repeatable first-run experiments, not for production deployment.

## Why this repository exists

Kerio Connect is normally installed as a traditional Linux package or virtual appliance. That is fine for manual administration, but it is awkward when you need a repeatable test environment for:

- first-run validation;
- licensing and restart behavior;
- persistent state and message store checks;
- log export to external Syslog or the related ELK pipeline;
- reproducible bug reports and CI-style smoke checks.

This repository solves that by wrapping the official Kerio Connect Debian package in a local Docker lab that keeps the vendor binaries in the image while persisting runtime data in Docker volumes.

## Project family

This repository is part of the **Kerio Connect Monitoring & Logging** project family:

1. [kerio-connect](https://github.com/foksk76/kerio-connect) — reproducible Kerio Connect lab environment
2. [kerio-logstash-project](https://github.com/foksk76/kerio-logstash-project) — parsing, normalization, and enrichment pipeline for Kerio syslog
3. [kerio-syslog-anonymizer](https://github.com/foksk76/kerio-syslog-anonymizer) — deterministic anonymization of real log data for safe public use

## Where this repository fits

This repository is the source-system lab in the family flow.

```text
Kerio Connect lab -> Syslog output -> kerio-logstash-project -> Elasticsearch / Kibana
                                   -> sample or sanitized logs -> kerio-syslog-anonymizer
```

Its job is to provide a reproducible Kerio Connect environment. It does not parse logs, normalize events, or anonymize data itself.

## Main use cases

- Stand up a repeatable Kerio Connect lab on Debian 13 with Docker Compose.
- Validate first-run behavior, restart persistence, and license handling.
- Test exposed admin and mail ports before integrating with downstream monitoring components.
- Export Kerio logs to an external Syslog receiver such as Logstash.
- Rebuild or reset a known-good lab environment without reinstalling the product manually.

## Audience

- beginner DevOps engineers
- sysadmins and homelab operators
- observability and SecOps practitioners preparing Kerio logging pipelines
- maintainers of the surrounding Kerio Connect Monitoring & Logging project family

## Architecture / Flow

1. `docker compose build` resolves the official Kerio Connect Debian installer from one of three sources:
   - local `artifacts/`
   - explicit `KERIO_DOWNLOAD_URL`
   - public Kerio archive auto-download
2. The image installs Kerio Connect plus wrapper scripts for startup, health checks, state seeding, and log-root handling.
3. `docker compose up -d` starts the lab with persistent Docker volumes for:
   - configuration state
   - message store
   - license directory
   - log directory
4. The operator completes the vendor first-run wizard through the admin endpoint on port `4040`.
   - during the initial setup phase, access may start at `http://localhost:4040/admin/`
   - after the initial setup is completed, Kerio Connect redirects admin access to `https://localhost:4040/admin/`
5. The running lab exposes admin and mail ports and can forward logs to an external Syslog target.
6. Validation happens through:
   - container health status
   - exposed ports
   - the admin web endpoint
   - Kerio service status inside the container

## Requirements

### Software

- Host OS: Linux host capable of running Docker; Debian 13 is the current target and tested path in this repository
- Docker Engine: required
- Docker Compose plugin: required
- Network access to official Kerio download hosts if you use auto-download
- Optional: a locally supplied official Kerio Connect `.deb` in `artifacts/` for offline or pinned builds

### Hardware

Vendor minimums for `1-20` users:

- CPU: `2 core`, `1 GHz`, `64-bit`
- RAM: `4 GB`
- Disk: `40 GB` free space for message store and backup

Practical lab recommendation for less painful testing:

- CPU: `4 vCPU`
- RAM: `8 GB`
- Disk: `60 GB`

### Tested versions

| Component | Version | Notes |
|---|---|---|
| Debian | 13 (Trixie) | current repository target |
| Docker Engine | 26.1.5+dfsg1 | verified locally |
| Docker Compose | 2.26.1-4 | verified locally |
| Kerio Connect | 10.0.9 | currently validated in this lab; exact build can change when auto-download is left enabled |

## Repository structure

```text
.
├── .env.example
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── pull_request_template.md
│   ├── release.yml
│   └── workflows/
│       └── docker-image.yml
├── artifacts/
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── Dockerfile
├── HANDOFF.md
├── NEXT_STEPS.md
├── README.md
├── SECURITY.md
├── SUPPORT.md
├── docker-compose.yml
└── scripts/
    ├── configure-log-root.sh
    ├── enable-git-hooks.sh
    ├── entrypoint.sh
    ├── healthcheck.sh
    ├── seed-state.sh
    └── update-commit-docs.sh
```

## Quick Start

> The commands below assume the default admin port `4040`. If you change `KERIO_ADMIN_PORT` in `.env`, substitute your chosen port in the verification commands. During the very first setup, `http://localhost:4040/admin/` may answer first; after the wizard is completed, admin access is expected on `https://localhost:4040/admin/`.

### 1. Clone the repository

```bash
git clone https://github.com/foksk76/kerio-connect.git
cd kerio-connect
git status --short
```

Expected result:

- the repository is cloned successfully;
- `git status --short` prints nothing for a clean checkout.

### 2. Prepare the environment

```bash
cp .env.example .env
scripts/enable-git-hooks.sh
docker compose config >/tmp/kerio-connect.compose.txt
sed -n '1,40p' /tmp/kerio-connect.compose.txt
```

Edit `.env` before the first build if any of these apply:

- `KERIO_ADMIN_PORT`: change this if `4040` is already in use
- `KERIO_SMTP_PORT`: keep `25` only if the host port is free; otherwise use something like `2525`
- `KERIO_VERSION_LABEL`: set this if you want a pinned Kerio archive version
- `KERIO_DOWNLOAD_URL`: set this only if you want an explicit official Linux DEB URL
- `KERIO_DOWNLOAD_SHA256`: set this if you want checksum verification for the downloaded DEB

If you need an offline or pinned local build, place exactly one official Kerio Connect Debian installer in `artifacts/`.

If the host already runs a local MTA on port `25`, stop it before startup or remap `KERIO_SMTP_PORT`:

```bash
systemctl stop postfix || true
ss -ltn '( sport = :25 )'
```

Expected result:

- `docker compose config` renders without errors;
- the generated config contains the `kerio-connect` service;
- host port `25` is either free or intentionally remapped in `.env`.

### 3. Run the project

```bash
docker compose build
docker compose up -d
docker compose ps
```

What to expect:

- the first build may take several minutes if the image downloads the vendor package from the public archive;
- `docker compose up -d` creates one service named `kerio-connect`;
- `docker compose ps` may show `health: starting` for a short time before it becomes `healthy`.

### 4. Verify the result

Check container state:

```bash
docker compose ps
```

Expected result:

- the `kerio-connect` service is `Up`;
- the health state becomes `healthy`.

Check exposed ports:

```bash
ss -ltn '( sport = :4040 or sport = :443 or sport = :25 or sport = :465 or sport = :587 or sport = :993 or sport = :995 )'
```

Expected result:

- listeners exist for the ports you mapped in `.env`;
- with default settings, the lab listens on `4040`, `443`, `25`, `465`, `587`, `993`, and `995`.

Check the Kerio service from inside the container:

```bash
docker compose exec -T kerio-connect /usr/local/bin/healthcheck.sh && echo HEALTHCHECK_OK
docker compose exec -T kerio-connect /etc/init.d/kerio-connect status
```

Expected result:

- the first command prints `HEALTHCHECK_OK`;
- the second command prints `Kerio Connect is running..`

Check initial web access:

```bash
wget --server-response --spider http://localhost:4040/admin/ 2>&1 | sed -n '1,20p'
wget --no-check-certificate --server-response --spider https://localhost:4040/admin/ 2>&1 | sed -n '1,20p'
```

Expected result:

- before the first-run wizard is completed, the `http://localhost:4040/admin/` check may return `HTTP/1.1 200 OK`
- after the initial setup is completed, the `https://localhost:4040/admin/` check returns `HTTP/1.1 200 OK`
- the response headers mention `Server: Kerio Connect`.

### 5. Example outcome

A successful default startup looks similar to this:

```text
NAME                IMAGE                         SERVICE         STATUS                 PORTS
kerio-connect-lab   kerio-connect-kerio-connect   kerio-connect   Up 7 hours (healthy)   0.0.0.0:25->25/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:4040->4040/tcp, ...
```

And the web probe should return a successful response:

```text
HTTP/1.1 200 OK
Server: Kerio Connect 10.0.9
```

At that point:

- the container is healthy;
- the admin page is reachable on port `4040`;
- the initial access path may begin on `http://localhost:4040/admin/`;
- after first-run completion, Kerio Connect redirects admin access to `https://localhost:4040/admin/`;
- you can open `https://localhost:4040/admin` in a browser;
- you will see either the vendor first-run wizard or the admin login page, depending on whether the lab has already been initialized.

## Example input

Example `.env` for a host where port `25` is already occupied and SMTP must be remapped:

```dotenv
CONTAINER_NAME=kerio-connect-lab
KERIO_HOSTNAME=kerio-connect
KERIO_AUTO_DOWNLOAD=1
KERIO_VERSION_LABEL=
KERIO_DOWNLOAD_URL=
KERIO_DOWNLOAD_SHA256=
KERIO_ADMIN_PORT=4040
KERIO_HTTPS_PORT=443
KERIO_SMTP_PORT=2525
KERIO_SMTPS_PORT=465
KERIO_SUBMISSION_PORT=587
KERIO_IMAPS_PORT=993
KERIO_POP3S_PORT=995
KERIO_MEMORY_LIMIT=4g
KERIO_CPUS=2.0
```

## Example output

Example verification output from a healthy lab:

```text
Kerio Connect is running..
Spider mode enabled. Check if remote file exists.
HTTP/1.1 200 OK
Server: Kerio Connect 10.0.9
```

## Verification checklist

- [ ] Repository cloned successfully
- [ ] `.env` prepared and reviewed
- [ ] `docker compose config` completed without errors
- [ ] `docker compose build` completed successfully
- [ ] `docker compose up -d` started the lab
- [ ] `docker compose ps` shows the service as `healthy`
- [ ] expected ports are listening on the host
- [ ] `http://localhost:4040/admin/` or `https://localhost:4040/admin/` is reachable, depending on setup state
- [ ] the first-run wizard or admin login page opens in the browser

## Troubleshooting

### Problem: port 25 is already in use

**Symptoms**

- `docker compose up -d` fails with a bind error for port `25`
- SMTP does not start on the expected host port

**Cause**

- another service, usually a local MTA such as `postfix`, is already listening on the host

**Solution**

```bash
systemctl stop postfix || true
sed -i 's/^KERIO_SMTP_PORT=25/KERIO_SMTP_PORT=2525/' .env
docker compose up -d
```

### Problem: build cannot find or download the Kerio installer

**Symptoms**

- `docker compose build` fails during the installer resolution step
- the build reports that no Kerio Connect Debian installer is available

**Cause**

- no local `.deb` exists in `artifacts/`
- auto-download cannot reach the official archive
- `KERIO_DOWNLOAD_URL` is empty or invalid

**Solution**

```bash
ls -la artifacts
grep -E '^(KERIO_AUTO_DOWNLOAD|KERIO_VERSION_LABEL|KERIO_DOWNLOAD_URL|KERIO_DOWNLOAD_SHA256)=' .env
docker compose build --no-cache
```

Then do one of the following:

- place one official Kerio Connect `.deb` in `artifacts/`
- set a valid official `KERIO_DOWNLOAD_URL`
- keep `KERIO_AUTO_DOWNLOAD=1` and make sure the host can reach `cdn.kerio.com`

### Problem: the admin page does not open

**Symptoms**

- `https://localhost:4040/admin` is unreachable
- the container stays in `health: starting` or `unhealthy`

**Cause**

- the container is still starting
- the chosen admin port differs from the default
- Kerio did not start cleanly inside the container

**Solution**

```bash
docker compose ps
docker compose logs --tail=200 kerio-connect
docker compose exec -T kerio-connect /usr/local/bin/healthcheck.sh
```

If you changed `KERIO_ADMIN_PORT` in `.env`, test that port instead of `4040`.

### Problem: the built-in trial link returns 404

**Symptoms**

- the first-run wizard sends you to an old `kerio.com` URL that no longer works

**Cause**

- the embedded Kerio Connect UI still references a legacy vendor trial link

**Solution**

Use the current manual trial entry point:

```text
https://gfi.ai/products-and-solutions/email-and-messaging-solutions/kerioconnect/free-trial
```

## Limitations / Non-goals

- This repository is not a production deployment model for Kerio Connect.
- This repository does not ship the Kerio Connect installer or license material.
- This repository is not a replacement for official vendor documentation or support.
- This repository does not automate the full vendor first-run wizard.
- This repository does not parse, normalize, enrich, or anonymize Kerio logs; that belongs to the other repositories in the project family.
- This repository does not guarantee reproducible vendor package availability when auto-download is enabled; local artifacts or pinned URLs are safer for long-term repeatability.

## Notes

- Kerio Connect itself is proprietary third-party software from GFI / Kerio.
- This repository wraps the official vendor package for lab use; it does not relicense or redistribute that software.
- The repository license, once defined in [LICENSE](./LICENSE), applies only to the wrapper code, scripts, and documentation in this repository, not to Kerio Connect vendor binaries.
- Default local verification does not require a public MX record. For basic first-run and admin access, a local hostname and browser access are enough.
- During initial setup, the admin UI may be reachable over `http://localhost:4040/admin/`; after the setup is completed, normal admin access is expected to redirect to `https://localhost:4040/admin/`.
- The current recommended external Syslog target pattern for the neighboring logging stack is `host.docker.internal:5514`.
- After a successful first run, it is sensible to take a VM backup or snapshot before deeper experimentation.
- The lab generates `en_US.UTF-8` and `ru_RU.UTF-8` during image build because Kerio administration expects UTF-8 locales to exist.

## Roadmap

See [NEXT_STEPS.md](./NEXT_STEPS.md)

## Changelog

See [CHANGELOG.md](./CHANGELOG.md)

## Handoff

See [HANDOFF.md](./HANDOFF.md) and [NEXT_STEPS.md](./NEXT_STEPS.md)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## Security

See [SECURITY.md](./SECURITY.md)

## Support

See [SUPPORT.md](./SUPPORT.md)

## License

See [LICENSE](./LICENSE)
