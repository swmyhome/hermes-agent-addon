FROM nousresearch/hermes-agent:latest
USER root
RUN apt-get update && \
    apt-get install -y python3-pip sudo && \
    rm -rf /var/lib/apt/lists/* && \
    echo "hermes ALL=(ALL) NOPASSWD: /usr/bin/apt-get" > /etc/sudoers.d/hermes && \
    chmod 0440 /etc/sudoers.d/hermes
COPY run.sh /run.sh
RUN chmod 755 /run.sh
ENTRYPOINT ["/run.sh"]
