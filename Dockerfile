FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive \
    KERIO_HOME=/opt/kerio/mailserver \
    KERIO_STATE_ROOT=/var/lib/kerio/state \
    KERIO_STORE_ROOT=/var/lib/kerio/store \
    KERIO_LOG_ROOT=/opt/kerio/logs

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      iproute2 \
      locales \
      net-tools \
      procps \
      psmisc \
      tini \
      xmlstarlet \
 && rm -rf /var/lib/apt/lists/*

COPY artifacts/ /tmp/artifacts/

RUN set -eux; \
    installer="$(find /tmp/artifacts -maxdepth 1 -type f -name '*.deb' | head -n 1)"; \
    if [ -z "${installer}" ]; then \
      echo "Place the official Kerio Connect Debian installer in artifacts/ before building." >&2; \
      exit 1; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends "${installer}"; \
    rm -rf /var/lib/apt/lists/* /tmp/artifacts

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh
COPY scripts/seed-state.sh /usr/local/bin/seed-state.sh
COPY scripts/configure-log-root.sh /usr/local/bin/configure-log-root.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
              /usr/local/bin/healthcheck.sh \
              /usr/local/bin/seed-state.sh \
              /usr/local/bin/configure-log-root.sh \
 && mkdir -p /var/lib/kerio/state /var/lib/kerio/store /opt/kerio/logs

EXPOSE 25 443 465 587 993 995 4040

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

