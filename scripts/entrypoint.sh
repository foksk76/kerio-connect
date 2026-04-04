#!/bin/sh
set -eu

if [ ! -x /etc/init.d/kerio-connect ]; then
  echo "Kerio Connect init script not found. Verify that the official .deb installer was provided during image build." >&2
  exit 1
fi

/usr/local/bin/seed-state.sh
/usr/local/bin/configure-log-root.sh

stop_service() {
  /etc/init.d/kerio-connect stop >/dev/null 2>&1 || true
}

trap stop_service INT TERM

/etc/init.d/kerio-connect start

while /etc/init.d/kerio-connect status >/dev/null 2>&1; do
  sleep 10
done

echo "Kerio Connect service is no longer running." >&2
exit 1
