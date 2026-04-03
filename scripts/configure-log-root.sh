#!/bin/sh
set -eu

KERIO_HOME="${KERIO_HOME:-/opt/kerio/mailserver}"
LOG_ROOT="${KERIO_LOG_ROOT:-/opt/kerio/logs}"
CONFIG_FILE="${KERIO_HOME}/mailserver.cfg"

if [ ! -f "${CONFIG_FILE}" ]; then
  exit 0
fi

if ! command -v xmlstarlet >/dev/null 2>&1; then
  exit 0
fi

update_xpath() {
  xpath="$1"
  tmp_file="$(mktemp)"

  if xmlstarlet sel -t -v "${xpath}" "${CONFIG_FILE}" >/dev/null 2>&1; then
    xmlstarlet ed -u "${xpath}" -v "${LOG_ROOT}" "${CONFIG_FILE}" > "${tmp_file}"
    mv "${tmp_file}" "${CONFIG_FILE}"
    echo "Configured Kerio log root to ${LOG_ROOT}"
    return 0
  fi

  rm -f "${tmp_file}"
  return 1
}

update_xpath "//*[local-name()='LogGlobal']//*[local-name()='RelativePathsRoot']" \
  || update_xpath "//*[@name='LogGlobal']//*[@name='RelativePathsRoot']" \
  || echo "Could not patch mailserver.cfg automatically; using symlink fallback for logs."
