#!/bin/sh
set -eu

KERIO_HOME="${KERIO_HOME:-/opt/kerio/mailserver}"
STATE_ROOT="${KERIO_STATE_ROOT:-/var/lib/kerio/state}"
STORE_ROOT="${KERIO_STORE_ROOT:-/var/lib/kerio/store}"
LOG_ROOT="${KERIO_LOG_ROOT:-/opt/kerio/logs}"

mkdir -p "${STATE_ROOT}" "${STORE_ROOT}" "${LOG_ROOT}"

seed_file() {
  src="$1"
  dst="$2"

  if [ -f "${src}" ] && [ ! -e "${dst}" ]; then
    cp "${src}" "${dst}"
  fi
}

seed_dir() {
  src="$1"
  dst="$2"

  if [ -d "${src}" ] && [ ! -e "${dst}" ]; then
    cp -a "${src}" "${dst}"
  fi
}

replace_with_symlink() {
  target="$1"
  link_path="$2"

  rm -rf "${link_path}"
  ln -s "${target}" "${link_path}"
}

seed_file "${KERIO_HOME}/mailserver.cfg" "${STATE_ROOT}/mailserver.cfg"
seed_file "${KERIO_HOME}/users.cfg" "${STATE_ROOT}/users.cfg"

if [ -d "${KERIO_HOME}/store" ] && [ ! -e "${STORE_ROOT}/.seeded-from-image" ]; then
  cp -a "${KERIO_HOME}/store/." "${STORE_ROOT}/" 2>/dev/null || true
  touch "${STORE_ROOT}/.seeded-from-image"
fi

replace_with_symlink "${STATE_ROOT}/mailserver.cfg" "${KERIO_HOME}/mailserver.cfg"
replace_with_symlink "${STATE_ROOT}/users.cfg" "${KERIO_HOME}/users.cfg"
replace_with_symlink "${STORE_ROOT}" "${KERIO_HOME}/store"

if [ -d "${STORE_ROOT}/logs" ] && [ ! -L "${STORE_ROOT}/logs" ]; then
  rm -rf "${STORE_ROOT}/logs"
fi

ln -sfn "${LOG_ROOT}" "${STORE_ROOT}/logs"
