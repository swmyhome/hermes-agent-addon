#!/usr/bin/env bash
set -e

echo "[hermes-addon] Starting Hermes Agent..."

#
# 1. Odczytanie konfiguracji z UI Home Assistanta
#
OPTIONS_FILE="/data/options.json"

if [ ! -f "$OPTIONS_FILE" ]; then
    echo "[hermes-addon] ERROR: $OPTIONS_FILE not found"
    exit 1
fi

USERNAME="$(python3 -c "import json; print(json.load(open('$OPTIONS_FILE')).get('username', 'admin'))")"
PASSWORD="$(python3 -c "import json; print(json.load(open('$OPTIONS_FILE')).get('password', ''))")"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "[hermes-addon] ERROR: Username or Password is empty in UI options"
    exit 1
fi

#
# 2. Inteligentna obsługa trwałości danych
#
APP_EXPECTED_DIR="/opt/data"
HA_PERSISTENT_DIR="/data"

echo "[hermes-addon] Setting up persistent storage..."

# Sprawdź, czy /opt/data jest już zamontowane jako wolumen (stąd błąd "Device or resource busy")
if mountpoint -q "$APP_EXPECTED_DIR"; then
    echo "[hermes-addon] $APP_EXPECTED_DIR is a mounted volume."
    echo "[hermes-addon] Attempting to overlay with persistent /data (mount --bind)..."
    
    # Próbujemy nałożyć /data na /opt/data
    if mount --bind "$HA_PERSISTENT_DIR" "$APP_EXPECTED_DIR"; then
        echo "[hermes-addon] Success! /data is now bound to $APP_EXPECTED_DIR."
    else
        echo "[hermes-addon] WARNING: mount --bind failed (missing privileges?)."
        echo "[hermes-addon] Falling back to default volume. Data will persist across restarts."
    fi
else
    # Jeśli to zwykły folder (nie jest zamontowany), usuwamy go i tworzymy symlink
    echo "[hermes-addon] $APP_EXPECTED_DIR is a regular directory. Creating symlink..."
    rm -rf "$APP_EXPECTED_DIR"
    ln -s "$HA_PERSISTENT_DIR" "$APP_EXPECTED_DIR"
    echo "[hermes-addon] Symlink created."
fi

# Nadaj uprawnienia
chmod -R 777 "$HA_PERSISTENT_DIR"

# Test zapisu
if ! touch "$APP_EXPECTED_DIR/.write_test" 2>/dev/null; then
    echo "[hermes-addon] ERROR: Cannot write to $APP_EXPECTED_DIR"
    exit 1
fi
rm -f "$APP_EXPECTED_DIR/.write_test"
echo "[hermes-addon] Persistent storage is writable."

#
# 3. Konfiguracja Dashboardu
#
export HERMES_DASHBOARD="1"
export HERMES_DASHBOARD_HOST="0.0.0.0"
export HERMES_DASHBOARD_PORT="9119" # Wewnętrzny port musi być 9119

export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="$USERNAME"
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$PASSWORD"

export HERMES_HOME="$APP_EXPECTED_DIR"
export HERMES_DATA="$APP_EXPECTED_DIR"

echo "[hermes-addon] Dashboard configured for user: $USERNAME on internal port 9119"

#
# 4. Weryfikacja
#
echo "[hermes-addon] Hermes version:"
hermes --version || true

#
# 5. Start Dashboard (w tle)
#
echo "[hermes-addon] Starting Hermes Dashboard..."

HERMES_HOME="$APP_EXPECTED_DIR" \
HERMES_DATA="$APP_EXPECTED_DIR" \
hermes dashboard \
    --host 0.0.0.0 \
    --port 9119 &

DASHBOARD_PID=$!
echo "[hermes-addon] Dashboard PID: $DASHBOARD_PID"

sleep 3

if ! kill -0 "$DASHBOARD_PID" 2>/dev/null; then
    echo "[hermes-addon] ERROR: Hermes Dashboard failed to start"
    exit 1
fi
echo "[hermes-addon] Dashboard started successfully"

#
# 6. Start Gateway (na pierwszym planie)
#
echo "[hermes-addon] Starting Hermes Gateway..."

exec env \
    HERMES_HOME="$APP_EXPECTED_DIR" \
    HERMES_DATA="$APP_EXPECTED_DIR" \
    hermes gateway run
