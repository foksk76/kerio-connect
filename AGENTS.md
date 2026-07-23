# Agent Instructions

Docker-based lab environment wrapping the official Kerio Connect Debian package on Debian 13. No application source code to compile — the "build" is a Docker image containing vendor binaries.

## Lab Purpose

- Reproducible local lab for safe Kerio Connect testing before production use.
- Source system for the **Kerio Connect Monitoring & Logging** project family.
- Sends syslog to `elastic.homelab:5514` for parsing, storage, and visualization.
- Provides log samples for `kerio-syslog-anonymizer` (safe public sharing).

Not a production deployment. Does not parse, anonymize, or store logs itself.

## Quick Commands

```bash
cp .env.example .env          # required first step
docker compose build           # build the lab image (downloads .deb if artifacts/ is empty)
docker compose up -d           # start the lab
docker compose ps              # check status; wait for health=healthy
docker compose logs --tail=200 kerio-connect
docker compose down -v         # tear down everything including volumes
```

Verify health inside the container:

```bash
docker compose exec -T kerio-connect /usr/local/bin/healthcheck.sh
docker compose exec -T kerio-connect /etc/init.d/kerio-connect status
```

## Critical Gotchas

- **Port 25 conflict**: Host MTA (e.g. postfix) will block Kerio SMTP. Run `ss -ltn '( sport = :25 )'` before starting. Either stop postfix or set `KERIO_SMTP_PORT=2525` in `.env`.
- **`.env` is gitignored** — never commit it. Edit `.env`, not `.env.example`.
- **`HANDOFF.md` and `NEXT_STEPS.md` are auto-generated** by `scripts/update-commit-docs.sh` via `.githooks/pre-commit`. Do not edit them by hand.
- **Git hooks are disabled by default per clone.** Run `scripts/enable-git-hooks.sh` once per clone to activate them.
- **Kerio Connect is proprietary** — the `artifacts/*.deb` and `artifacts/*.rpm` patterns are gitignored. Never commit vendor binaries.

## Architecture

| Component | Path | Role |
|---|---|---|
| Dockerfile | `Dockerfile` | Debian 13 image, installs Kerio .deb, copies scripts |
| Compose | `docker-compose.yml` | Service definition, ports, volumes, healthcheck |
| Env config | `.env.example` → `.env` | User-editable build/runtime parameters |
| Vendor .deb | `artifacts/` (gitignored) | Optional local installer for offline/pinned builds |
| Scripts | `scripts/` | entrypoint, healthcheck, seed-state, configure-log-root, git hook helpers |
| Lab state | `.lab-state.env` | First-run status, read by `update-commit-docs.sh` |
| CI | `.github/workflows/docker-image.yml` | Builds image + smoke test on ubuntu-latest |

### Build-time Installer Resolution (Dockerfile order)

1. Local `.deb` in `artifacts/` — takes priority.
2. Explicit `KERIO_DOWNLOAD_URL` — downloaded directly.
3. `KERIO_AUTO_DOWNLOAD=1` — resolves latest from `cdn.kerio.com` archive index.
4. If none available, build fails with a clear error.

### Container Internals

- Entry: `tini` → `scripts/entrypoint.sh` → `seed-state.sh` → `configure-log-root.sh` → `/etc/init.d/kerio-connect start`
- Healthcheck: curls `https://127.0.0.1:4040/admin/` or falls back to init script status.
- Key paths inside container: `/opt/kerio/mailserver/` (home), `/var/lib/kerio/state/`, `/var/lib/kerio/store/`

## Project Family & Data Flow

This repo is part of the **Kerio Connect Monitoring & Logging** family. Each repo runs its own lab host:

| Lab host | Repo | Role |
|---|---|---|
| `kerio.homelab` | `kerio-connect` (this repo) | Source system: Kerio Connect mail server |
| `elastic.homelab` | `kerio-logstash-project` | Syslog ingestion, parsing, Elasticsearch storage |
| `grafana.homelab` | `kerio-logstash-project` | Dashboards and visualization |

Data flow:

```
kerio.homelab  --syslog-->  elastic.homelab  -->  grafana.homelab
     |                           |
     |                     Elasticsearch
     |                     Logstash pipeline
     |
     +-- log samples -->  kerio-syslog-anonymizer
```

- Kerio Connect sends syslog to `elastic.homelab:5514` (application name `kerio`).
- `kerio-syslog-anonymizer` consumes log samples for safe public sharing.
- Syslog target is configured manually in the Kerio admin UI after first-run setup.

### Lab Access (SSH)

`kerio.homelab` is this host — work directly in the local shell. The other two are remote, accessible via SSH key auth through ssh-agent. No password required.

```bash
# this host — local shell
docker compose ps

# remote hosts — via SSH
ssh root@elastic.homelab    # logstash / elasticsearch lab
ssh root@grafana.homelab    # grafana lab
```

## CI Behavior

- Triggers on push/PR to `main` when Dockerfile, compose, scripts, or workflow changes.
- Uses high-numbered ports (44040, 44443, 40025, etc.) to avoid host conflicts.
- Waits up to 5 minutes for healthy status, runs healthcheck, then tears down with `docker compose down -v`.

## Kerio Connect Administration API

JSON-RPC 2.0 API on port `4040`. Full reference: https://manuals.gfi.com/en/kerio/api/connect/admin/reference/

### Authentication

```bash
# Login — returns session token + cookie
curl -sk -X POST https://kerio.homelab:4040/admin/api/jsonrpc \
  -H "Content-Type: application/json" \
  -c /tmp/kerio-cookies.txt \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"Session.login",
    "params":{
      "userName":"Admin",
      "password":"",
      "application":{"name":"Lab API","vendor":"Lab","version":"1.0"}
    }
  }'
# Response: {"result":{"token":"<token>"}}
```

**Important:** Built-in admin `Admin` (empty password) is available when `BuiltInAdminEnabled=1` in `mailserver.cfg`. The `doge@kerio.homelab` account requires its own password.

### Session management

- Every subsequent request must include `"token":"<token>"` in the JSON body **and** the `X-Token` HTTP header.
- Session cookie (`SESSION_CONNECT_WEBADMIN`) is returned on login; pass it via `-b /tmp/kerio-cookies.txt`.
- Sessions expire after inactivity; re-login if you get `code: -32001`.

### Key API methods

| Method | Purpose |
|---|---|
| `Session.login` | Authenticate, get token |
| `Session.logout` | End session |
| `Users.get` | List users in a domain |
| `Users.create` | Create new users |
| `Users.set` | Update user properties |
| `Users.remove` | Delete users |
| `Domains.get` | List domains |
| `ServerInfo.get` | Server version, features, license |

### Common patterns

**Get domain ID:**
```bash
curl -sk -X POST https://kerio.homelab:4040/admin/api/jsonrpc \
  -H "Content-Type: application/json" -H "X-Token: $TOKEN" -b /tmp/kerio-cookies.txt \
  -d '{"jsonrpc":"2.0","id":2,"token":"'"$TOKEN"'","method":"Domains.get","params":{"query":{}}}'
# Domain ID format: keriodb://domain/<guid>
```

**Create user:**
```bash
curl -sk -X POST https://kerio.homelab:4040/admin/api/jsonrpc \
  -H "Content-Type: application/json" -H "X-Token: $TOKEN" -b /tmp/kerio-cookies.txt \
  -d '{
    "jsonrpc":"2.0","id":3,"token":"'"$TOKEN"'",
    "method":"Users.create",
    "params":{"users":[{
      "domainId":"'"$DOMAIN_ID"'",
      "loginName":"test.user",
      "fullName":"Test User",
      "password":"test1234",
      "isEnabled":true
    }]}
  }'
# Required fields: domainId, loginName, password
```

**List users:**
```bash
curl -sk -X POST https://kerio.homelab:4040/admin/api/jsonrpc \
  -H "Content-Type: application/json" -H "X-Token: $TOKEN" -b /tmp/kerio-cookies.txt \
  -d '{"jsonrpc":"2.0","id":4,"token":"'"$TOKEN"'","method":"Users.get","params":{"query":{},"domainId":"'"$DOMAIN_ID"'"}}'
```

**Remove users:**
```bash
curl -sk -X POST https://kerio.homelab:4040/admin/api/jsonrpc \
  -H "Content-Type: application/json" -H "X-Token: $TOKEN" -b /tmp/kerio-cookies.txt \
  -d '{
    "jsonrpc":"2.0","id":5,"token":"'"$TOKEN"'",
    "method":"Users.remove",
    "params":{"requests":[
      {"userId":"<user-id>","method":"UDeleteFolder","removeReferences":false,"targetUserId":""}
    ]}
  }'
# Method values: UDeleteUser, UDeleteFolder, UMoveFolder
```

### License limits

The lab runs on a trial license (25 users max). `Users.create` returns error code `1003` ("user count license exceeded") when the limit is reached. Delete unused users before creating new ones.

## Documentation Conventions

- `README.md` is the canonical English source; `README.ru.md` is a Russian translation that must not document separate behavior.
- Both READMEs must start with the language-switcher line: `Language: [English](README.md) | [Русский](README.ru.md)`
- `CHANGELOG.md` is English-only.
- GitHub release notes are written for DevOps/sysadmin audience, focused on what changed for operators.
