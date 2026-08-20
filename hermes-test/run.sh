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

#
# Persistent Hermes storage
#
export HERMES_HOME="/opt/data"

echo "[hermes-addon] Hermes home: $HERMES_HOME"

#
# Create persistent directories
#
echo "[hermes-addon] Preparing persistent directories..."

mkdir -p "$HERMES_HOME"
mkdir -p "$HERMES_HOME/logs"

#
# Make sure Hermes owns its persistent data
#
echo "[hermes-addon] Fixing permissions..."

mkdir -p "$HERMES_HOME"
mkdir -p "$HERMES_HOME/logs"

chmod -R 777 "$HERMES_HOME"

echo "[hermes-addon] Storage permissions:"
ls -ld "$HERMES_HOME"
ls -ld "$HERMES_HOME/logs"

#
# Test write access
#
echo "[hermes-addon] Testing write access..."

TEST_FILE="$HERMES_HOME/.write_test"

if ! touch "$TEST_FILE" 2>/dev/null; then
    echo "[hermes-addon] ERROR: Cannot write to $HERMES_HOME"
    echo "[hermes-addon] Check add-on filesystem permissions."
    exit 1
fi

rm -f "$TEST_FILE"

echo "[hermes-addon] Persistent storage is writable."

#
# Dashboard configuration
#
export HERMES_DASHBOARD="1"
export HERMES_DASHBOARD_HOST="0.0.0.0"
export HERMES_DASHBOARD_PORT="$PORT"

export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="$USERNAME"
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$PASSWORD"

echo "[hermes-addon] Dashboard username: $USERNAME"
echo "[hermes-addon] Dashboard port: $PORT"

#
# Hermes version
#
echo "[hermes-addon] Hermes version:"
hermes --version || true

#
# Existing Hermes configuration
#
if [ -f "$HERMES_HOME/config.yaml" ]; then
    echo "[hermes-addon] Existing config.yaml found."
else
    echo "[hermes-addon] No existing config.yaml found."
fi

if [ -f "$HERMES_HOME/state.db" ]; then
    echo "[hermes-addon] Existing state.db found."
else
    echo "[hermes-addon] No existing state.db found."
fi

#
# Start Dashboard
#
echo "[hermes-addon] Starting Hermes Dashboard..."

HOME="$HERMES_HOME" \
HERMES_HOME="$HERMES_HOME" \
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

#
# Start Gateway
#
echo "[hermes-addon] Starting Hermes Gateway..."

exec env \
    HOME="$HERMES_HOME" \
    HERMES_HOME="$HERMES_HOME" \
    hermes gateway run
