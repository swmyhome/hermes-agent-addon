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
# 2. PLAN B: Tworzenie Symlinku (Trwałość danych)
# Aplikacja oczekuje katalogu /opt/data. 
# My przekierujemy go do trwałego /data z Home Assistanta.
#
APP_EXPECTED_DIR="/opt/data"
HA_PERSISTENT_DIR="/data"

echo "[hermes-addon] Setting up persistent storage via symlink..."

# Jeśli /opt/data istnieje jako zwykły folder (z obrazu Docker), usuwamy go
if [ -d "$APP_EXPECTED_DIR" ] && [ ! -L "$APP_EXPECTED_DIR" ]; then
    echo "[hermes-addon] Removing default $APP_EXPECTED_DIR directory from image..."
    rm -rf "$APP_EXPECTED_DIR"
fi

# Tworzymy symlink: /opt/data wskazuje teraz na /data
if [ ! -L "$APP_EXPECTED_DIR" ]; then
    echo "[hermes-addon] Creating symlink: $APP_EXPECTED_DIR -> $HA_PERSISTENT_DIR"
    ln -s "$HA_PERSISTENT_DIR" "$APP_EXPECTED_DIR"
fi

# Nadajemy pełne uprawnienia, aby aplikacja w kontenerze mogła tu pisać
chmod -R 777 "$HA_PERSISTENT_DIR"

# Test zapisu (dla pewności)
if ! touch "$APP_EXPECTED_DIR/.write_test" 2>/dev/null; then
    echo "[hermes-addon] ERROR: Cannot write to $APP_EXPECTED_DIR (symlink failed?)"
    exit 1
fi
rm -f "$APP_EXPECTED_DIR/.write_test"
echo "[hermes-addon] Persistent storage is writable and linked correctly."

#
# 3. Konfiguracja Dashboardu
#
export HERMES_DASHBOARD="1"
export HERMES_DASHBOARD_HOST="0.0.0.0"
# WAŻNE: Port wewnętrzny w kontenerze MUSI być 9119 (zgodnie z config.json)
export HERMES_DASHBOARD_PORT="9119" 

export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="$USERNAME"
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$PASSWORD"

# Ustawiamy zmienne środowiskowe na ścieżkę z symlinkiem (dla pewności)
export HERMES_HOME="$APP_EXPECTED_DIR"
export HERMES_DATA="$APP_EXPECTED_DIR"

echo "[hermes-addon] Dashboard configured for user: $USERNAME on internal port 9119"
echo "[hermes-addon] HERMES_HOME and HERMES_DATA set to: $APP_EXPECTED_DIR"

#
# 4. Weryfikacja
#
echo "[hermes-addon] Hermes version:"
hermes --version || true

#
# 5. Start Dashboard (w tle)
#
echo "[hermes-addon] Starting Hermes Dashboard..."

# Uruchamiamy Dashboard w tle (&)
# NIE nadpisujemy systemowej zmiennej HOME, tylko HERMES_HOME/DATA
HERMES_HOME="$APP_EXPECTED_DIR" \
HERMES_DATA="$APP_EXPECTED_DIR" \
hermes dashboard \
    --host 0.0.0.0 \
    --port 9119 &

DASHBOARD_PID=$!
echo "[hermes-addon] Dashboard PID: $DASHBOARD_PID"

sleep 3 # Dajemy chwilę na start

if ! kill -0 "$DASHBOARD_PID" 2>/dev/null; then
    echo "[hermes-addon] ERROR: Hermes Dashboard failed to start"
    exit 1
fi
echo "[hermes-addon] Dashboard started successfully"

#
# 6. Start Gateway (na pierwszym planie - to utrzyma kontener przy życiu)
#
echo "[hermes-addon] Starting Hermes Gateway..."

exec env \
    HERMES_HOME="$APP_EXPECTED_DIR" \
    HERMES_DATA="$APP_EXPECTED_DIR" \
    hermes gateway run
