ARG BUILD_FROM

FROM $BUILD_FROM

ARG BUILD_ARCH
ARG SEMAPHORE_VERSION

RUN if [ "${BUILD_ARCH}" == "aarch64" ]; then BUILD_ARCH=arm64; \
    elif [ "${BUILD_ARCH}" == "i386" ]; then BUILD_ARCH=386; \
    fi && \
    apk add --no-cache -U \
      nginx git curl gnupg openssh-client-default sshpass rsync python3 py3-pip && \
    wget --quiet -O /tmp/semaphore.tar.gz "https://github.com/semaphoreui/semaphore/releases/download/v${SEMAPHORE_VERSION}/semaphore_${SEMAPHORE_VERSION}_linux_${BUILD_ARCH}.tar.gz" && \
    tar xzvf /tmp/semaphore.tar.gz -C /usr/local/bin semaphore && \
    chmod +x /usr/local/bin/semaphore && \
    rm -fr \
      /tmp/* \
      /etc/nginx

COPY rootfs /

ENV ANSIBLE_VERSION=9.4.0

RUN pip3 install --upgrade pip ansible==${ANSIBLE_VERSION} boto3 botocore requests

# Copy data for add-on
COPY start_semaphore_ui.sh /
RUN chmod a+x /start_semaphore_ui.sh

CMD [ "/start_semaphore_ui.sh" ]
