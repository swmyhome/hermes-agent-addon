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

if [ -z "$PASSWORD" ]; then
    echo "[hermes-addon] ERROR: Dashboard password is empty"
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

echo "[hermes-addon] Dashboard configuration:"
echo "  HERMES_DASHBOARD=$HERMES_DASHBOARD"
echo "  HERMES_DASHBOARD_HOST=$HERMES_DASHBOARD_HOST"
echo "  HERMES_DASHBOARD_PORT=$HERMES_DASHBOARD_PORT"
echo "  HERMES_DASHBOARD_BASIC_AUTH_USERNAME=$HERMES_DASHBOARD_BASIC_AUTH_USERNAME"

echo "[hermes-addon] Starting Hermes Gateway..."

exec hermes gateway run
