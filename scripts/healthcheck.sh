#!/bin/sh
set -eu

if curl -kfsS https://127.0.0.1:4040/admin/ >/dev/null 2>&1; then
  exit 0
fi

if curl -kfsS https://127.0.0.1:4040/ >/dev/null 2>&1; then
  exit 0
fi

/etc/init.d/kerio-connect status >/dev/null 2>&1

