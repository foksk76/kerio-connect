#!/bin/sh
set -eu

if [ ! -x /etc/init.d/kerio-connect ]; then
  echo "Kerio Connect init script not found. Verify that the official .deb installer was provided during image build." >&2
  exit 1
fi

/usr/local/bin/seed-state.sh
/usr/local/bin/configure-log-root.sh

KERIO_DOMAIN="${KERIO_DOMAIN:-}"

stop_service() {
  /etc/init.d/kerio-connect stop >/dev/null 2>&1 || true
}

trap stop_service INT TERM

/etc/init.d/kerio-connect start

if [ -n "${KERIO_DOMAIN}" ]; then
  sleep 2
  cfg="${KERIO_STATE_ROOT:-/var/lib/kerio/state}/mailserver.cfg"
  if [ -f "${cfg}" ]; then
    current="$(xmlstarlet sel -t -v "//*[local-name()=\"variable\"][@name=\"InternetHostname\"]" "${cfg}" 2>/dev/null || true)"
    if [ -n "${current}" ] && [ "${current}" != "${KERIO_DOMAIN}" ]; then
      sed -i "s|<variable name=\"InternetHostname\">${current}</variable>|<variable name=\"InternetHostname\">${KERIO_DOMAIN}</variable>|" "${cfg}"
      echo "Patched InternetHostname to ${KERIO_DOMAIN}"
      /etc/init.d/kerio-connect restart >/dev/null 2>&1 || true
    fi
  fi
  ucfg="${KERIO_STATE_ROOT:-/var/lib/kerio/state}/users.cfg"
  if [ -f "${ucfg}" ]; then
    ucurrent="$(xmlstarlet sel -t -v "//*[local-name()=\"variable\"][@name=\"Domain\"]" "${ucfg}" 2>/dev/null | head -1 || true)"
    if [ -n "${ucurrent}" ] && [ "${ucurrent}" != "${KERIO_DOMAIN}" ]; then
      sed -i "s|<variable name=\"Domain\">${ucurrent}</variable>|<variable name=\"Domain\">${KERIO_DOMAIN}</variable>|g" "${ucfg}"
      echo "Patched Domain to ${KERIO_DOMAIN}"
      /etc/init.d/kerio-connect restart >/dev/null 2>&1 || true
    fi
  fi
fi

while /etc/init.d/kerio-connect status >/dev/null 2>&1; do
  sleep 10
done

echo "Kerio Connect service is no longer running." >&2
exit 1
