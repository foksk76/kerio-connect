# Next Steps

1. Open the project on the target host at `/root/kerio-connect`.
2. Copy this repo there or recreate the same file layout.
3. Put the official Kerio Connect Debian installer into `artifacts/`.
4. Create `.env` from [`.env.example`](.env.example) if needed.
5. Run:

```bash
docker compose build
docker compose up -d
docker compose logs --tail=200
```

6. Verify the real package layout:
   - `/etc/init.d/kerio-connect`
   - `/opt/kerio/mailserver/mailserver.cfg`
   - `/opt/kerio/mailserver/users.cfg`
   - `/opt/kerio/mailserver/license`
   - `/opt/kerio/mailserver/store`

7. Verify that `scripts/configure-log-root.sh` can move logs to `/opt/kerio/logs`.
8. If XML patching does not match the real config, keep the symlink fallback and adjust the script.
9. Open `https://<host>:4040/admin` and complete the official first-run wizard.
10. In Kerio Connect Administration, enable external Syslog logging and point it to the Logstash receiver.

More context:

- [HANDOFF.md](HANDOFF.md)
- [README.md](README.md)
