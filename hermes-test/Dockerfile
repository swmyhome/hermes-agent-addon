FROM nousresearch/hermes-agent:latest

# Skopiowanie skryptu startowego do kontenera
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Ustawienie run.sh jako domyślnego entrypointu
ENTRYPOINT ["/run.sh"]
