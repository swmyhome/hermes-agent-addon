#!/usr/bin/env bash
set -e

echo "[INFO] Uruchamianie Hermes Agent Add-on..."

# Tworzenie pliku konfiguracji w aktualnej wersji, aby usunąć błąd migracji
CONFIG_FILE="/root/.hermes/config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[INFO] Tworzenie domyślnej konfiguracji..."
    mkdir -p /root/.hermes
    cat <<EOF > "$CONFIG_FILE"
_config_version: 12
agent:
  model: "claude-opus-4.6"
EOF
fi

echo "[INFO] Startowanie usługi w tle..."

# Uruchamiamy usługę i podtrzymujemy działanie kontenera
if hermes gateway --help >/dev/null 2>&1; then
    exec hermes gateway
elif hermes server --help >/dev/null 2>&1; then
    exec hermes server
else
    hermes start || true
    tail -f /dev/null
fi
