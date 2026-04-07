Language: [English](README.md) | [Русский](README.ru.md)

# Kerio Connect Lab

Reproducible Docker-based lab environment for Kerio Connect on Debian 13.

[![Docker Lab CI](https://github.com/foksk76/kerio-connect/actions/workflows/docker-image.yml/badge.svg)](https://github.com/foksk76/kerio-connect/actions/workflows/docker-image.yml)

> **Project status:** Lab-friendly project for safely checking Kerio Connect behavior before production use.

> **Language policy:** `README.md` is the main English README. `README.ru.md` is the main Russian translation for lab work and quick onboarding. Keep the language switcher as the first line in both files.

## Why this repository exists

Kerio Connect is normally installed as a traditional Linux package or virtual appliance. That works for manual administration, but it is inconvenient when an engineer needs a repeatable local environment for first-run checks, restart validation, licensing tests, and log-export experiments.

This repository builds a local Docker lab around the official Kerio Connect Debian package. It keeps vendor binaries in the image and persists runtime state, license files, the message store, and logs in Docker volumes so the lab can be rebuilt without losing the important data layer.

## Project family

This repository is part of the **Kerio Connect Monitoring & Logging** project family:

1. [kerio-connect](https://github.com/foksk76/kerio-connect) — reproducible Kerio Connect lab environment
2. [kerio-logstash-project](https://github.com/foksk76/kerio-logstash-project) — parser and storage pipeline for Kerio syslog
3. [kerio-syslog-anonymizer](https://github.com/foksk76/kerio-syslog-anonymizer) — deterministic anonymization of real log data for safe public use

## Where this repository fits

This repository provides the reproducible Kerio Connect source-system lab.

```text
kerio-connect -> Kerio syslog -> kerio-logstash-project -> Elasticsearch / Kibana
                              -> log samples -> kerio-syslog-anonymizer
```

The related repositories complement each other:

- `kerio-connect` provides a reproducible Kerio Connect lab.
- `kerio-logstash-project` parses, normalizes, validates, and stores Kerio syslog in an ELK-oriented pipeline.
- `kerio-syslog-anonymizer` prepares real logs for safe public sharing while keeping deterministic values for correlation.

## Main Usage Flow

1. An engineer prepares `.env` and chooses how the official Kerio Connect Debian installer is supplied.
2. `docker compose build` creates a Debian 13 image with Kerio Connect and the repository wrapper scripts.
3. `docker compose up -d` starts the Kerio Connect lab and mounts persistent Docker volumes.
4. The engineer opens the admin UI on port `4040` and completes the vendor first-run wizard.
5. Kerio Connect runs as the source system for mail-service checks and optional Syslog export.
6. Engineers verify the result through container health, exposed ports, internal service status, and the admin endpoint.

## Who This Is For

- Kerio Connect administrators who need a safe local lab before changing a real service.
- DevOps, observability, or SecOps engineers preparing Kerio syslog ingestion work.
- Homelab users and project contributors who need a repeatable environment for documentation, CI, and troubleshooting.

## Architecture / Component Roles

1. **Source system**: Kerio Connect running inside the lab container.
2. **Build wrapper**: `Dockerfile` installs the official Kerio Connect Debian package from `artifacts/`, `KERIO_DOWNLOAD_URL`, or the public Kerio archive.
3. **Runtime orchestration**: `docker-compose.yml` exposes admin and mail ports and defines CPU, memory, healthcheck, and volume settings.
4. **Persistence layer**: Docker volumes preserve config state, the message store, license files, and logs.
5. **Scripts / tooling**: `scripts/` seeds persistent state, patches the log-root path when possible, starts Kerio Connect, and performs health checks.
6. **Downstream logging**: Kerio Connect can be configured to send selected logs to an external Syslog receiver such as the related Logstash project.

## Requirements

### Software

- OS: Linux host capable of running Docker; Debian 13 is the current target and tested local path.
- Docker: required.
- Docker Compose plugin: required.
- Network access: required when `KERIO_AUTO_DOWNLOAD=1` and no local installer exists in `artifacts/`.
- Optional local artifact: one official Kerio Connect Debian `.deb` in `artifacts/` for offline or pinned builds.

### Hardware

- CPU: vendor minimum for `1-20` users is `2 core`, `1 GHz`, `64-bit`; practical lab recommendation is `4 vCPU`.
- RAM: vendor minimum is `4 GB`; practical lab recommendation is `8 GB`.
- Disk: vendor minimum is `40 GB` free space for message store and backup; practical lab recommendation is `60 GB`.

### Tested versions

| Component | Version | Notes |
|---|---|---|
| Debian | 13 (Trixie) | current repository target |
| Docker Engine | 26.1.5+dfsg1 | verified locally |
| Docker Compose | 2.26.1-4 | verified locally |
| Kerio Connect | 10.0.9 | validated in this lab; exact build can change when auto-download is left enabled |

## Repository structure

- `Dockerfile` builds the Debian 13 Kerio Connect lab image.
- `docker-compose.yml` starts the local Kerio Connect service, ports, healthcheck, and persistent volumes.
- `.env.example` documents configurable build args, ports, resource limits, and volume names.
- `artifacts/` is the optional local location for an official Kerio Connect `.deb` installer.
- `scripts/` contains entrypoint, healthcheck, state seeding, log-root handling, and commit-doc helpers.
- `.github/workflows/docker-image.yml` runs the Docker lab CI workflow.
- `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`, and `.github/release.yml` define GitHub collaboration templates.
- `README.md`, `README.ru.md`, `CHANGELOG.md`, `HANDOFF.md`, and `NEXT_STEPS.md` describe onboarding, project history, handoff context, and next steps.
- `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `LICENSE`, and `THIRD_PARTY_NOTICE.md` describe project governance, reporting, support, and license boundaries.

## Documentation language policy

- `README.md` is the main English source.
- `README.ru.md` is the main Russian translation for lab work and quick onboarding.
- The first line of both README files is the language switcher:

```md
Language: [English](README.md) | [Русский](README.ru.md)
```

- The Russian README follows the English README and does not document separate behavior.
- If the English README changes, update `README.ru.md` in the same release when feasible. If not feasible, add a short translation freshness note near the top of `README.ru.md`.
- `CHANGELOG.md` is maintained in English. Do not create or require a Russian changelog unless there is a strong project-specific reason.
- `CONTRIBUTING.md` is maintained in English; Russian README changes are welcome when they preserve the meaning of the English version.

## Quick Start

> Short path: build and start the local Kerio Connect lab, confirm that the container is healthy, verify exposed ports, and open the admin UI.

You will:

- prepare `.env`;
- build the Kerio Connect lab image;
- start the `kerio-connect` service;
- verify container health and exposed ports;
- open the initial admin endpoint.

### 1. Clone the repository

```bash
git clone https://github.com/foksk76/kerio-connect.git
cd kerio-connect
ls README.md docker-compose.yml .env.example
```

If all is well:

- the current directory is the repository root;
- `README.md`, `docker-compose.yml`, and `.env.example` are present.

### 2. Prepare the environment

```bash
cp .env.example .env
scripts/enable-git-hooks.sh
docker compose config >/tmp/kerio-connect.compose.txt
sed -n '1,40p' /tmp/kerio-connect.compose.txt
```

**What you can edit**

- `KERIO_ADMIN_PORT`: change this if host port `4040` is already in use.
- `KERIO_SMTP_PORT`: keep `25` only if the host port is free; otherwise use a value such as `2525`.
- `KERIO_VERSION_LABEL`: set this when you want to pin a Kerio archive version.
- `KERIO_DOWNLOAD_URL`: set this only when you want an explicit official Linux DEB URL.
- `KERIO_DOWNLOAD_SHA256`: set this when you want checksum verification for the downloaded DEB.
- `KERIO_MEMORY_LIMIT` and `KERIO_CPUS`: adjust these if the lab host has different resource limits.

**What matters**

- Keep `KERIO_AUTO_DOWNLOAD=1` if you want the build to resolve the current public Kerio Connect Linux DEB from the official archive.
- Place exactly one official Kerio Connect Debian installer in `artifacts/` if you need an offline or pinned local build.
- Stop the local MTA or remap `KERIO_SMTP_PORT` if the host already listens on port `25`.

```bash
systemctl stop postfix || true
ss -ltn '( sport = :25 )'
```

If all is well:

- `docker compose config` renders without errors;
- the generated config includes the `kerio-connect` service;
- host port `25` is either free or intentionally remapped in `.env`.

### 3. Run the project

```bash
docker compose build
docker compose up -d
docker compose ps
```

If all is well:

- the image builds successfully;
- one service named `kerio-connect` starts;
- `docker compose ps` shows the container as `Up`;
- the health state may be `starting` briefly and should become `healthy`.

If you connect a production or external source:

- do not point production mail traffic at this lab by default;
- for log testing, configure Kerio external Syslog manually in the Kerio administration UI after first-run setup;
- use a test or lab Syslog receiver first, for example the related `kerio-logstash-project`.

### 4. Verify the result

Check container state:

```bash
docker compose ps
```

If all is well:

- the `kerio-connect` service is `Up`;
- the health state is `healthy`.

Check exposed ports:

```bash
ss -ltn '( sport = :4040 or sport = :443 or sport = :25 or sport = :465 or sport = :587 or sport = :993 or sport = :995 )'
```

If all is well:

- listeners exist for the ports mapped in `.env`;
- with default settings, the lab listens on `4040`, `443`, `25`, `465`, `587`, `993`, and `995`.

Check the Kerio service inside the container:

```bash
docker compose exec -T kerio-connect /usr/local/bin/healthcheck.sh && echo HEALTHCHECK_OK
docker compose exec -T kerio-connect /etc/init.d/kerio-connect status
```

If all is well:

- the first command prints `HEALTHCHECK_OK`;
- the second command prints `Kerio Connect is running..`.

Check initial web access:

```bash
wget --server-response --spider http://localhost:4040/admin/ 2>&1 | sed -n '1,20p'
wget --no-check-certificate --server-response --spider https://localhost:4040/admin/ 2>&1 | sed -n '1,20p'
```

If all is well:

- during first-run setup, `http://localhost:4040/admin/` may answer first;
- after first-run setup, Kerio Connect redirects admin access to `https://localhost:4040/admin/`;
- the HTTPS response includes `HTTP/1.1 200 OK`;
- the response headers mention `Server: Kerio Connect`.

### 5. Confirm the outcome

After the steps above:

- the local Kerio Connect lab is running;
- the admin UI is reachable on port `4040`;
- persistent Docker volumes exist for state, store, license, and logs;
- you can complete the vendor first-run wizard in a browser;
- after first-run completion, normal admin access is expected at `https://localhost:4040/admin/`.

## Audit Matrix Run

This repository does not currently include a separate audit or protocol matrix runner.

Use the normal Quick Start checks for first-time onboarding. If protocol-level audit coverage is added later, document the required live service, identities, mail clients, and expected artifacts here.

## Minimal Parser Event

This repository is not a parser, so there is no parser event to send through the project.

The closest minimal operational input is a small `.env` override for a host where SMTP port `25` is already occupied:

```dotenv
CONTAINER_NAME=kerio-connect-lab
KERIO_HOSTNAME=kerio-connect
KERIO_AUTO_DOWNLOAD=1
KERIO_ADMIN_PORT=4040
KERIO_SMTP_PORT=2525
KERIO_MEMORY_LIMIT=4g
KERIO_CPUS=2.0
```

## Normalized Result

This repository does not produce a normalized parser event.

The expected operational result is a healthy Kerio Connect lab:

```text
Kerio Connect is running..
HEALTHCHECK_OK
HTTP/1.1 200 OK
Server: Kerio Connect 10.0.9
```

## Verification checklist

- [ ] Repository cloned successfully
- [ ] Environment prepared
- [ ] Services started
- [ ] Verification commands passed
- [ ] Output matches the documented example

## Troubleshooting

### Problem: port 25 is already in use

**Symptoms**

- `docker compose up -d` fails with a bind error for port `25`.
- SMTP does not start on the expected host port.

**What to check**

- A local MTA such as `postfix` may already be listening on host port `25`.
- `KERIO_SMTP_PORT` may still be set to the default `25`.

**How to fix it**

```bash
systemctl stop postfix || true
sed -i 's/^KERIO_SMTP_PORT=25/KERIO_SMTP_PORT=2525/' .env
docker compose up -d
```

### Problem: build cannot find or download the Kerio installer

**Symptoms**

- `docker compose build` fails during the installer resolution step.
- The build reports that no Kerio Connect Debian installer is available.

**What to check**

- `artifacts/` may not contain an official Kerio Connect `.deb`.
- The host may not be able to reach `cdn.kerio.com`.
- `KERIO_DOWNLOAD_URL` may be empty or invalid.

**How to fix it**

```bash
ls -la artifacts
grep -E '^(KERIO_AUTO_DOWNLOAD|KERIO_VERSION_LABEL|KERIO_DOWNLOAD_URL|KERIO_DOWNLOAD_SHA256)=' .env
docker compose build --no-cache
```

Then use one of these paths:

- place one official Kerio Connect `.deb` in `artifacts/`;
- set a valid official `KERIO_DOWNLOAD_URL`;
- keep `KERIO_AUTO_DOWNLOAD=1` and ensure the host can reach `cdn.kerio.com`.

### Problem: the admin page does not open

**Symptoms**

- `http://localhost:4040/admin/` or `https://localhost:4040/admin/` is unreachable.
- The container stays in `health: starting` or `unhealthy`.

**What to check**

- The container may still be starting.
- `KERIO_ADMIN_PORT` may differ from the default `4040`.
- Kerio Connect may not have started cleanly inside the container.

**How to fix it**

```bash
docker compose ps
docker compose logs --tail=200 kerio-connect
docker compose exec -T kerio-connect /usr/local/bin/healthcheck.sh
```

If you changed `KERIO_ADMIN_PORT` in `.env`, test that port instead of `4040`.

### Problem: the built-in trial link returns 404

**Symptoms**

- The first-run wizard sends you to an old `kerio.com` URL that no longer works.

**What to check**

- The embedded Kerio Connect UI may still reference a legacy vendor trial link.

**How to fix it**

Use the current manual trial entry point:

```text
https://gfi.ai/products-and-solutions/email-and-messaging-solutions/kerioconnect/free-trial
```

## What This Project Does Not Do

- It does not provide a production deployment model for Kerio Connect.
- It does not ship the Kerio Connect installer or license material.
- It does not replace official GFI / Kerio documentation or support.
- It does not automate the full vendor first-run wizard.
- It does not parse, normalize, enrich, or anonymize Kerio logs; those roles belong to the other repositories in the project family.
- It does not guarantee reproducible vendor package availability when auto-download is enabled; local artifacts or pinned URLs are safer for long-term repeatability.

## What To Know Before Use

- Kerio Connect itself is proprietary third-party software from GFI / Kerio.
- This repository wraps the official vendor package for lab use; it does not relicense or redistribute that software.
- [LICENSE](./LICENSE) applies to the wrapper code, scripts, and documentation in this repository, not to Kerio Connect vendor binaries.
- See [THIRD_PARTY_NOTICE.md](./THIRD_PARTY_NOTICE.md) for the proprietary software boundary.
- During initial setup, the admin UI may be reachable over `http://localhost:4040/admin/`; after setup, admin access is expected to redirect to `https://localhost:4040/admin/`.
- Default local verification does not require a public MX record.
- The recommended external Syslog target pattern for the neighboring logging stack is `host.docker.internal:5514`.
- After a successful first run, take a VM backup or snapshot before deeper experimentation.
- The lab generates `en_US.UTF-8` and `ru_RU.UTF-8` during image build because Kerio administration expects UTF-8 locales to exist.

## Roadmap

See [NEXT_STEPS.md](./NEXT_STEPS.md)

## Changelog

See [CHANGELOG.md](./CHANGELOG.md)

Keep `CHANGELOG.md` canonical and English-only unless a repository explicitly decides otherwise. Do not duplicate release entries into a localized changelog by default.

## Handoff

See [HANDOFF.md](./HANDOFF.md)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

Contribution guidelines should state that:

- English is the main language for project documentation and review;
- Russian README updates are welcome when they preserve the meaning of the English README;
- Russian documentation should help onboarding without changing documented behavior.

## GitHub Release Notes

GitHub Release Notes stay in English.

Write them for DevOps engineers, sysadmins, and lab engineers. Focus on what changed for someone running, validating, or troubleshooting the project:

- what users can now run, observe, validate, or troubleshoot;
- exact local checks, live run IDs, CI status, and expected pass/fail signals when they prove readiness;
- required engineer action, configuration changes, migration notes, known limitations, manual-only steps, or superseded release notes.

Avoid implementation-heavy or file-by-file wording unless it changes how engineers use the project.

## Security

See [SECURITY.md](./SECURITY.md)

## Support

See [SUPPORT.md](./SUPPORT.md)

## License

See [LICENSE](./LICENSE)
