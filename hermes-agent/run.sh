#!/bin/bash

set -e

echo "[hermes-addon] Starting Hermes Agent..."

OPTIONS_FILE="/data/options.json"

if [ ! -f "$OPTIONS_FILE" ]; then
    echo "[hermes-addon] ERROR: $OPTIONS_FILE not found"
    exit 1
fi

USERNAME="$(python3 -c "import json; print(json.load(open('$OPTIONS_FILE')).get('username', 'admin'))")"
PASSWORD="$(python3 -c "import json; print(json.load(open('$OPTIONS_FILE')).get('password', ''))")"
PORT="$(python3 -c "import json; print(json.load(open('$OPTIONS_FILE')).get('port', 9119))")"

if [ -z "$USERNAME" ]; then
    echo "[hermes-addon] ERROR: Username is empty"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    echo "[hermes-addon] ERROR: Password is empty"
    exit 1
fi

echo "[hermes-addon] Dashboard username: $USERNAME"
echo "[hermes-addon] Dashboard port: $PORT"

export HERMES_DASHBOARD="1"
export HERMES_DASHBOARD_HOST="0.0.0.0"
export HERMES_DASHBOARD_PORT="$PORT"

export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="$USERNAME"
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$PASSWORD"

echo "[hermes-addon] Hermes version:"
hermes --version || true

echo "[hermes-addon] Starting Hermes Dashboard..."

hermes dashboard \
    --host 0.0.0.0 \
    --port "$PORT" &

DASHBOARD_PID=$!

echo "[hermes-addon] Dashboard PID: $DASHBOARD_PID"

sleep 2

if ! kill -0 "$DASHBOARD_PID" 2>/dev/null; then
    echo "[hermes-addon] ERROR: Hermes Dashboard failed to start"
    exit 1
fi

echo "[hermes-addon] Dashboard started successfully"

echo "[hermes-addon] Starting Hermes Gateway..."

exec hermes gateway run
