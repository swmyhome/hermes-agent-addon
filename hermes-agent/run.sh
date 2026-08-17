#!/bin/bash

set -e

echo "[hermes-addon] Starting Hermes Agent..."

OPTIONS_FILE="/data/options.json"
HERMES_HOME="/config"

#
# Check options
#
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

if [ -z "$PORT" ]; then
    PORT="9119"
fi

#
# Persistent Hermes home
#
export HERMES_HOME="$HERMES_HOME"

echo "[hermes-addon] Hermes home: $HERMES_HOME"

#
# Make sure persistent directories exist
#
echo "[hermes-addon] Preparing persistent directories..."

mkdir -p "$HERMES_HOME"
mkdir -p "$HERMES_HOME/logs"
mkdir -p "$HERMES_HOME/sessions"
mkdir -p "$HERMES_HOME/skills"
mkdir -p "$HERMES_HOME/cron"
mkdir -p "$HERMES_HOME/state"

#
# Try to fix permissions.
#
# This is intentionally non-fatal because Home Assistant may
# manage ownership of the mounted addon directory.
#
echo "[hermes-addon] Checking permissions..."

chmod -R u+rwX "$HERMES_HOME" 2>/dev/null || true

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
# Existing configuration
#
if [ -f "$HERMES_HOME/config.yaml" ]; then
    echo "[hermes-addon] Existing Hermes configuration found:"
    echo "[hermes-addon] $HERMES_HOME/config.yaml"
else
    echo "[hermes-addon] No existing config.yaml found."
    echo "[hermes-addon] Hermes will create its configuration when needed."
fi

#
# Existing state database
#
if [ -f "$HERMES_HOME/state.db" ]; then
    echo "[hermes-addon] Existing Hermes state database found."
else
    echo "[hermes-addon] No existing state.db found."
fi

#
# Start Dashboard
#
echo "[hermes-addon] Starting Hermes Dashboard..."

hermes dashboard \
    --host 0.0.0.0 \
    --port "$PORT" &

DASHBOARD_PID=$!

echo "[hermes-addon] Dashboard PID: $DASHBOARD_PID"

sleep 3

if ! kill -0 "$DASHBOARD_PID" 2>/dev/null; then
    echo "[hermes-addon] ERROR: Hermes Dashboard failed to start"
    exit 1
fi

echo "[hermes-addon] Dashboard started successfully"

#
# Dashboard ready marker
#
echo "HERMES_DASHBOARD_READY port=$PORT"

#
# Start Gateway
#
echo "[hermes-addon] Starting Hermes Gateway..."

exec hermes gateway run
