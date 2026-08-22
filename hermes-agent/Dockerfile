FROM nousresearch/hermes-agent:latest

USER root

# 1. Zainstaluj sudo + pip
RUN apt-get update && \
    apt-get install -y sudo python3-pip && \
    rm -rf /var/lib/apt/lists/*

# 2. Dodaj regułę sudoers z PRAWIDŁOWYMI uprawnieniami (0440)
RUN echo "hermes ALL=(ALL) NOPASSWD: /usr/bin/apt-get" > /etc/sudoers.d/hermes && \
    chmod 0440 /etc/sudoers.d/Hermes

COPY run.sh /run.sh

RUN chmod 755 /run.sh

ENTRYPOINT ["/run.sh"]
