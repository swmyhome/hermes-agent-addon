#!/usr/bin/env bash
set -e

echo "[hermes-addon] Starting Hermes Agent..."

OPTIONS_FILE="/data/options.json"

if [ ! -f "$OPTIONS_FILE" ]; then
    echo "[hermes-addon] ERROR: $OPTIONS_FILE not found"
    exit 1
fi

# Odczytanie danych z UI
USERNAME="$(python3 -c "import json; print(json.load(open('$OPTIONS_FILE')).get('username', 'admin'))")"
PASSWORD="$(python3 -c "import json; print(json.load(open('$OPTIONS_FILE')).get('password', ''))")"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "[hermes-addon] ERROR: Username or Password is empty"
    exit 1
fi

#
# 1. Trwały katalog danych (Zostawiamy tylko /data)
#
export HERMES_DATA="/opt/data"
echo "[hermes-addon] Persistent data directory: $HERMES_DATA"

#
# 2. Przygotowanie katalogu i uprawnień
#
echo "[hermes-addon] Preparing persistent storage..."
mkdir -p "$HERMES_DATA/logs"
chmod -R 777 "$HERMES_DATA"

# Test zapisu
if ! touch "$HERMES_DATA/.write_test" 2>/dev/null; then
    echo "[hermes-addon] ERROR: Cannot write to $HERMES_DATA"
    exit 1
fi
rm -f "$HERMES_DATA/.write_test"
echo "[hermes-addon] Persistent storage is writable."

#
# 3. Konfiguracja Dashboardu
#
export HERMES_DASHBOARD="1"
export HERMES_DASHBOARD_HOST="0.0.0.0"
export HERMES_DASHBOARD_PORT="9119" # Wewnętrzny port musi być 9119

export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="$USERNAME"
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$PASSWORD"

echo "[hermes-addon] Dashboard configured for user: $USERNAME on port 9119"

#
# 4. Weryfikacja (Sprawdzamy teraz bezpośrednio w /data)
#
echo "[hermes-addon] Hermes version:"
hermes --version || true

if [ -f "$HERMES_DATA/config.yaml" ]; then
    echo "[hermes-addon] Existing config.yaml found in /data."
else
    echo "[hermes-addon] No config.yaml found. App will generate defaults."
fi

#
# 5. Start Dashboard (w tle)
#
echo "[hermes-addon] Starting Hermes Dashboard..."

# Przekazujemy tylko HERMES_DATA. Nie nadpisujemy systemowego HOME!
HERMES_DATA="$HERMES_DATA" \
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
    HERMES_DATA="$HERMES_DATA" \
    hermes gateway run
