# Next Steps

Generated automatically on 2026-04-05 08:28:08 UTC.

## Current Observed State

- Repository path: `/root/kerio-connect`
- Branch: `main`
- Kerio image: `kerio-connect-kerio-connect:latest 1GB`
- Postfix service: `inactive`
- Host port 25: `busy: LISTEN 0      4096         0.0.0.0:25        0.0.0.0:*    users:(("docker-proxy",pid=449,fd=4))`
- First run: `completed`
- Admin account: `doge@kerio.lo`
- Primary domain: `kerio.lo`
- Hostname: `kerio.lo`
- Message store: `/opt/kerio/mailserver/store/`
- License note: `Built-in trial link points to the legacy kerio.com trial URL and currently returns HTTP 404; use the manual GFI Free Trial URL from README.md.`
- DNS note: `HomeLab DNS publishes kerio.lo as an internal A record only; no MX record is expected in this lab. External GFI hosts still resolve from inside the container, so the telemetry DNS warning is tracked separately.`
- Syslog note: `External Syslog is enabled for mail, operations, security, spam, and audit to elastic.lo:5514 with application name kerio.`

## Compose Status

- `kerio-connect`: Up 8 hours (healthy), health `healthy`

## Immediate Steps

1. Sign in to `https://localhost:4040/admin` as `doge@kerio.lo` and continue post-setup tasks.
2. Keep host port `25` free for Kerio by stopping or disabling the local MTA, or remap `KERIO_SMTP_PORT` in `.env`.
3. Built-in trial link points to the legacy kerio.com trial URL and currently returns HTTP 404; use the manual GFI Free Trial URL from README.md.
4. Verify the package layout inside the container or image:
   - `/etc/init.d/kerio-connect`
   - `/opt/kerio/mailserver/mailserver.cfg`
   - `/opt/kerio/mailserver/users.cfg`
   - `/opt/kerio/mailserver/license`
   - `/opt/kerio/mailserver/store`
5. Confirm that `scripts/configure-log-root.sh` still matches the real `mailserver.cfg` shape and that logs can be redirected to `/opt/kerio/logs`.
6. Verify remote Syslog delivery for `mail`, `operations`, `security`, `spam`, and `audit` on `elastic.lo:5514` with application name `kerio`.

## Commit Automation

Run this once per clone or host to enable repository hooks:

```bash
scripts/enable-git-hooks.sh
```
