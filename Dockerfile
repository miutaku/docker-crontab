FROM alpine:3.12 as rq-build

ENV RQ_VERSION=1.0.2
WORKDIR /root/

RUN apk --update add upx \
    && ARCH=$(uname -m) \
    && [ "$ARCH" = "x86_64" ] && ARCH="x86_64" \
    && [ "$ARCH" = "arm64" ] && ARCH="aarch64" \
    && FILENAME=rq-v${RQ_VERSION}-${ARCH}-unknown-linux-musl.tar.gz \
    && wget https://github.com/dflemstr/rq/releases/download/v${RQ_VERSION}/${FILENAME} \
    && tar -xvf ${FILENAME} \
    && upx --brute rq

FROM library/docker:stable

COPY --from=rq-build /root/rq /usr/local/bin

ENV HOME_DIR=/opt/crontab
RUN apk add --no-cache --virtual .run-deps gettext jq bash tini \
    && mkdir -p ${HOME_DIR}/jobs ${HOME_DIR}/projects \
    && adduser -S docker -D

COPY docker-entrypoint /
ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint"]

HEALTHCHECK --interval=5s --timeout=3s \
    CMD ps aux | grep '[c]rond' || exit 1

CMD ["crond", "-f", "-d", "6", "-c", "/etc/crontabs"]
