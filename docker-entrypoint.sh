#!/bin/sh
# Reads secrets from Bitwarden at start when a machine-account token is present, so Coolify only carries the token and secret ids.
#   HEXBRAIN_API_KEY_SECRET_ID, GOOGLE_CLIENT_ID_SECRET_ID, GOOGLE_CLIENT_SECRET_SECRET_ID name the Bitwarden secrets to read.
# The import secrets (cve.now, HackerOne) are read by scripts/refresh.sh, so the web server never holds them.
set -e
. /app/scripts/secrets.sh
fetch HEXBRAIN_API_KEY "$HEXBRAIN_API_KEY_SECRET_ID"
fetch GOOGLE_CLIENT_ID "$GOOGLE_CLIENT_ID_SECRET_ID"
fetch GOOGLE_CLIENT_SECRET "$GOOGLE_CLIENT_SECRET_SECRET_ID"
exec "$@"
