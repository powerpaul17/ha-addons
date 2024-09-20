ARG BUILD_FROM

FROM $BUILD_FROM

ARG BUILD_ARCH
ARG SEMAPHORE_VERSION

RUN if [ "${BUILD_ARCH}" == "aarch64" ]; then BUILD_ARCH=arm64; \
    elif [ "${BUILD_ARCH}" == "i386" ]; then BUILD_ARCH=386; \
    fi && \
    wget --quiet -O /tmp/semaphore.tar.gz "https://github.com/semaphoreui/semaphore/releases/download/v${SEMAPHORE_VERSION}/semaphore_${SEMAPHORE_VERSION}_linux_${BUILD_ARCH}.tar.gz" && \
    tar xzvf /tmp/semaphore.tar.gz -C /usr/local/bin semaphore && \
    chmod +x /usr/local/bin/semaphore && \
    rm -f /tmp/*

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD /run.sh
