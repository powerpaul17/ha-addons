ARG BUILD_FROM

ARG KOMODO_VERSION

ARG KOMODO_CORE_IMAGE=ghcr.io/moghtech/komodo-core:${KOMODO_VERSION}

FROM ${KOMODO_CORE_IMAGE} AS komodo-core

FROM ${BUILD_FROM}

# Install needed packages

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      wget \
      git \
      unzip \
      nginx \
      postgresql-common

RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

RUN apt-get install -y --no-install-recommends \
      postgresql-15 \
      postgresql-15-cron \
      postgresql-15-pgvector \
      postgresql-15-postgis-3 \
      postgresql-15-rum

ARG BUILD_ARCH
ARG FERRETDB_VERSION

# FerretDB

RUN if [ "${BUILD_ARCH}" == "aarch64" ]; then BUILD_ARCH=arm64; \
    fi \
    && wget --quiet -O /tmp/ferretdb.deb "https://github.com/FerretDB/FerretDB/releases/download/v${FERRETDB_VERSION}/ferretdb-${BUILD_ARCH}-linux.deb" \
    && wget --quiet -O /tmp/documentdb.deb "https://github.com/FerretDB/documentdb/releases/download/v0.103.0-ferretdb-${FERRETDB_VERSION}/deb12-postgresql-15-documentdb_0.103.0.ferretdb.${FERRETDB_VERSION}_${BUILD_ARCH}.deb"

RUN dpkg -i /tmp/ferretdb.deb
RUN dpkg -i /tmp/documentdb.deb

RUN rm -rf \
      /tmp/* \
      /etc/nginx

# Copy files

COPY rootfs /

# Copy binaries

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
