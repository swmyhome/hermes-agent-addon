#!/usr/bin/env bash
set -e

# Ustawienie zmiennych środowiskowych (zgodnie z Twoją konfiguracją docker run)
export HERMES_DASHBOARD="true"
export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="admin"
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="admin"

# Opcjonalnie: wypisanie informacji do logów Home Assistant
echo "[Info] Uruchamianie Hermes Agent..."
echo "[Info] Dashboard włączony. Logowanie: admin/admin"

# Uruchomienie oryginalnej aplikacji (przekazuje oryginalne CMD z obrazu Docker)
exec "$@"
