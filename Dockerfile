FROM debian:13

ARG KERIO_AUTO_DOWNLOAD=1
ARG KERIO_VERSION_LABEL=
ARG KERIO_DOWNLOAD_URL=
ARG KERIO_DOWNLOAD_SHA256=
ARG KERIO_ARCHIVE_INDEX_URL=https://cdn.kerio.com/archive/index.php?type=source
ARG KERIO_ARCHIVE_DOWNLOAD_URL=https://cdn.kerio.com/archive/download.php

ENV DEBIAN_FRONTEND=noninteractive \
    KERIO_HOME=/opt/kerio/mailserver \
    KERIO_STATE_ROOT=/var/lib/kerio/state \
    KERIO_STORE_ROOT=/var/lib/kerio/store \
    KERIO_LOG_ROOT=/opt/kerio/logs \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

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
      wget \
      xmlstarlet \
 && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && sed -i 's/^# *ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen \
 && locale-gen en_US.UTF-8 ru_RU.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

COPY artifacts/ /tmp/artifacts/

RUN set -eux; \
    urlencode() { \
      printf '%s' "$1" \
      | sed \
          -e 's/%/%25/g' \
          -e 's/ /%20/g' \
          -e 's/(/%28/g' \
          -e 's/)/%29/g' \
          -e 's/+/%2B/g' \
          -e 's/&/%26/g'; \
    }; \
    installer="$(find /tmp/artifacts -maxdepth 1 -type f -name '*.deb' | head -n 1)"; \
    if [ -z "${installer}" ]; then \
      if [ -n "${KERIO_DOWNLOAD_URL}" ]; then \
        installer="/tmp/kerio-connect-downloaded.deb"; \
        echo "Downloading Kerio Connect from override URL: ${KERIO_DOWNLOAD_URL}"; \
        wget -4 --tries=20 --timeout=120 --waitretry=2 --progress=dot:giga \
          -O "${installer}" "${KERIO_DOWNLOAD_URL}"; \
      elif [ "${KERIO_AUTO_DOWNLOAD}" = "1" ]; then \
        version_label="${KERIO_VERSION_LABEL}"; \
        if [ -z "${version_label}" ]; then \
          version_label="$(wget -4 -qO- --tries=20 --timeout=120 --waitretry=2 \
            "${KERIO_ARCHIVE_INDEX_URL}" | tr '\n' ' ' | sed -n 's/.*var version0= new Array(\"\",\"\([^\"]*\)\".*/\1/p')"; \
        fi; \
        if [ -z "${version_label}" ]; then \
          echo "Could not resolve the latest Kerio Connect version label from ${KERIO_ARCHIVE_INDEX_URL}." >&2; \
          exit 1; \
        fi; \
        archive_post_data="product=Kerio%20Connect&version=$(urlencode "${version_label}")"; \
        download_url="$(wget -4 -qO- --tries=20 --timeout=120 --waitretry=2 \
          --post-data="${archive_post_data}" \
          "${KERIO_ARCHIVE_DOWNLOAD_URL}" \
          | sed -n '/Kerio Connect - Linux 64bit (DEB)/{n;s/.*href=\"\([^\"]*linux-amd64\.deb\)\".*/\1/p;}' \
          | head -n 1)"; \
        if [ -z "${download_url}" ]; then \
          echo "Could not resolve the official Kerio Connect Linux DEB download URL for version: ${version_label}" >&2; \
          exit 1; \
        fi; \
        installer="/tmp/kerio-connect-downloaded.deb"; \
        echo "Resolved Kerio Connect version: ${version_label}"; \
        echo "Downloading Kerio Connect from official archive: ${download_url}"; \
        wget -4 --tries=20 --timeout=120 --waitretry=2 --progress=dot:giga \
          -O "${installer}" "${download_url}"; \
      else \
        echo "Place the official Kerio Connect Debian installer in artifacts/, set KERIO_DOWNLOAD_URL, or leave KERIO_AUTO_DOWNLOAD=1." >&2; \
        exit 1; \
      fi; \
    fi; \
    if [ -n "${KERIO_DOWNLOAD_SHA256}" ]; then \
      echo "${KERIO_DOWNLOAD_SHA256}  ${installer}" | sha256sum -c -; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends "${installer}"; \
    rm -f "${installer}"; \
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
