ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.19
FROM ${BUILD_FROM}

# Pobieramy warstwy z obrazu Nous Research
FROM nousresearch/hermes-agent:latest AS hermes

# Łączymy z bazą Home Assistant
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    jq \
    curl

# Kopiujemy całe środowisko Hermesa
COPY --from=hermes / /

RUN mkdir -p /opt/data /root/.hermes

COPY run.sh /
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
