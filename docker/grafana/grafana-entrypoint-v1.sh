#!/usr/bin/env sh

###########################
# NAME: Grafana entry     #
# AUTHOR: DesertRatz      #
# CREATED: 2026/08/08     #
# (C) 2022-2026           #
###########################

set -eu

# Read admin username/password from mounted secret files
export GRAFANA_USER="$(cat /run/secrets/grafana_user)"
export GRAFANA_PASSWORD="$(cat /run/secrets/grafana_password)"

# Remove any stray newlines (defensive)
export GRAFANA_USER="$(printf "%s" "$GRAFANA_USER" | tr -d '\r\n')"
export GRAFANA_PASSWORD="$(printf "%s" "$GRAFANA_PASSWORD" | tr -d '\r\n')"

# Start Grafana (the official image entrypoint calls /run.sh)
exec /run.sh