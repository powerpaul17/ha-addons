ARG BUILD_FROM

ARG KOMODO_CORE_IMAGE=ghcr.io/mbecker20/komodo

FROM ${KOMODO_CORE_IMAGE} AS komodo-core

FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG FERRETDB_VERSION

# Install needed packages

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      wget \
      git \
      unzip

# FerretDB

RUN if [ "${BUILD_ARCH}" == "aarch64" ]; then BUILD_ARCH=arm64; \
    fi \
    && wget --quiet -O /tmp/ferretdb.deb "https://github.com/FerretDB/FerretDB/releases/download/v${FERRETDB_VERSION}/ferretdb-linux-${BUILD_ARCH}.deb" \
    && dpkg -i /tmp/ferretdb.deb

# Copy files

COPY rootfs /

# Copy binaries

COPY --from=komodo-core /config/config.toml /config/config.toml
COPY --from=komodo-core /app/frontend /app/frontend
COPY --from=komodo-core /usr/local/bin/core /usr/local/bin/core
COPY --from=komodo-core /usr/local/bin/deno /usr/local/bin/deno

# Set $DENO_DIR and preload external Deno deps
ENV DENO_DIR=/action-cache/deno
RUN mkdir /action-cache && \
	cd /action-cache && \
	deno install jsr:@std/yaml jsr:@std/toml

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
