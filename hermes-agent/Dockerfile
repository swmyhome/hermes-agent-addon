FROM nousresearch/hermes-agent:latest

USER root

# Instalacja pip
RUN apt-get update && \
    apt-get install -y python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Opcjonalnie: daj userowi hermes uprawnienia do apt
RUN echo "hermes ALL=(ALL) NOPASSWD: /usr/bin/apt-get" >> /etc/sudoers

COPY run.sh /run.sh

RUN chmod 755 /run.sh

ENTRYPOINT ["/run.sh"]
