#!/usr/bin/with-contenv bashio

set -e

bashio::log.info "Starting Hermes Agent Add-on..."

USERNAME="$(bashio::config 'username')"
PASSWORD="$(bashio::config 'password')"
PORT="$(bashio::config 'port')"

if [ -z "${USERNAME}" ]; then
    bashio::log.error "Username cannot be empty!"
    exit 1
fi

if [ -z "${PASSWORD}" ]; then
    bashio::log.error "Password cannot be empty!"
    exit 1
fi

if [ -z "${PORT}" ]; then
    PORT="9119"
fi

bashio::log.info "Dashboard username: ${USERNAME}"
bashio::log.info "Dashboard port: ${PORT}"

export HERMES_DASHBOARD="1"
export HERMES_DASHBOARD_HOST="0.0.0.0"
export HERMES_DASHBOARD_PORT="${PORT}"

export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="${USERNAME}"
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="${PASSWORD}"

# Stable signing key for dashboard sessions.
if [ ! -f /config/hermes-dashboard-secret ]; then
    bashio::log.info "Generating dashboard session secret..."

    SECRET="$(python3 -c 'import secrets; print(secrets.token_urlsafe(48))')"

    printf '%s' "${SECRET}" > /config/hermes-dashboard-secret
    chmod 600 /config/hermes-dashboard-secret
fi

export HERMES_DASHBOARD_BASIC_AUTH_SECRET="$(cat /config/hermes-dashboard-secret)"

bashio::log.info "Hermes Dashboard enabled."
bashio::log.info "Starting Hermes Gateway..."

exec hermes gateway run
