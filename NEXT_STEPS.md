# Next Steps

Generated automatically on 2026-04-03 16:09:31 UTC.

## Current Observed State

- Repository path: `/root/kerio-connect`
- Branch: `main`
- Kerio image: `kerio-connect-kerio-connect:latest 998MB`
- Postfix service: `inactive`
- Host port 25: `busy: LISTEN 0      4096         0.0.0.0:25        0.0.0.0:*    users:(("docker-proxy",pid=25435,fd=4))`

## Compose Status

- `kerio-connect`: Up 17 minutes (healthy), health `healthy`

## Immediate Steps

1. Open `https://localhost:4040/admin` and finish the first-run wizard.
2. Keep host port `25` free for Kerio by stopping or disabling the local MTA, or remap `KERIO_SMTP_PORT` in `.env`.
3. Verify the package layout inside the container or image:
   - `/etc/init.d/kerio-connect`
   - `/opt/kerio/mailserver/mailserver.cfg`
   - `/opt/kerio/mailserver/users.cfg`
   - `/opt/kerio/mailserver/license`
   - `/opt/kerio/mailserver/store`
4. Confirm that `scripts/configure-log-root.sh` still matches the real `mailserver.cfg` shape and that logs can be redirected to `/opt/kerio/logs`.
5. Enable external Syslog logging in Kerio Connect Administration and point it at the Logstash receiver once the wizard is complete.

## Commit Automation

Run this once per clone or host to enable repository hooks:

```bash
scripts/enable-git-hooks.sh
```
