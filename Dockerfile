# syntax=docker/dockerfile:latest
FROM golang:alpine AS builder
LABEL maintainer="Valeriu Stinca <ts@strat.zone>"
LABEL version="1.0"
LABEL vendor="Strategic Zone"
LABEL release-date="2024-08-04"

WORKDIR /usr/local/src
RUN <<eot
  apk add --no-cache git
  go install github.com/prometheus-community/ipmi_exporter@latest
eot

FROM alpine:edge
LABEL maintainer="Valeriu Stinca <ts@strat.zone>"
LABEL version="1.0"
LABEL vendor="Strategic Zone"
LABEL release-date="2024-08-04"

ENV CONFIG_FILE="${CONFIG_FILE:-/app/config.yml}"

WORKDIR /app

COPY --from=builder /go/bin/ipmi_exporter /bin/ipmi_exporter

RUN <<eot
  apk add --no-cache bash freeipmi-libs freeipmi
  rm -rf /var/cache/apk/*
eot

EXPOSE 9290/tcp

USER nobody
ENTRYPOINT ["/bin/ipmi_exporter"]
CMD ["--config.file", "/app/config.yml"]