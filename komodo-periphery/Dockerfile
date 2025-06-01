ARG BUILD_FROM

ARG KOMODO_PERIPHERY_IMAGE=ghcr.io/moghtech/komodo-periphery

FROM ${KOMODO_PERIPHERY_IMAGE} AS komodo-periphery

FROM ${BUILD_FROM}

# Copy binaries

COPY --from=komodo-periphery /usr/local/bin/periphery /usr/local/bin/periphery

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
