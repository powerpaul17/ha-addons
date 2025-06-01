ARG BUILD_FROM

ARG KOMODO_CORE_IMAGE=ghcr.io/moghtech/komodo-core

FROM ${KOMODO_CORE_IMAGE} AS komodo-core

FROM ${BUILD_FROM}

ARG BUILD_ARCH

# Install needed packages

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      wget \
      git \
      unzip \
      nginx

# FerretDB

RUN if [ "${BUILD_ARCH}" == "aarch64" ]; then BUILD_ARCH=arm64; \
    fi \
    && wget --quiet -O /tmp/mongodb.deb "https://repo.mongodb.org/apt/ubuntu/dists/focal/mongodb-org/8.0/multiverse/binary-${BUILD_ARCH}/mongodb-org-server_8.0.9_${BUILD_ARCH}.deb" \
    && dpkg -i /tmp/mongodb.deb

RUN rm -rf \
      /tmp/* \
      /etc/nginx

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
