#!/bin/sh
# Reads secrets from Bitwarden at start when a machine-account token is present, so Coolify only carries the token and secret ids.
#   HEXBRAIN_API_KEY_SECRET_ID, GOOGLE_CLIENT_ID_SECRET_ID, GOOGLE_CLIENT_SECRET_SECRET_ID name the Bitwarden secrets to read.
set -e
fetch() { # $1 = variable to set, $2 = Bitwarden secret id
  [ -n "$2" ] || return 0
  v=$(bws secret get "$2" 2>/dev/null | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.parse(s).value||"")}catch{}})')
  if [ -n "$v" ]; then export "$1=$v"; else echo "entrypoint: could not read secret for $1" >&2; fi
}
if [ -n "$BWS_ACCESS_TOKEN" ]; then
  fetch HEXBRAIN_API_KEY "$HEXBRAIN_API_KEY_SECRET_ID"
  fetch GOOGLE_CLIENT_ID "$GOOGLE_CLIENT_ID_SECRET_ID"
  fetch GOOGLE_CLIENT_SECRET "$GOOGLE_CLIENT_SECRET_SECRET_ID"
fi
exec "$@"
