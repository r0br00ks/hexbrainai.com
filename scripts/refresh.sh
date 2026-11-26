#!/bin/sh
# Data refresh for the container. Run by hand or from a Coolify scheduled task:
#   sh scripts/refresh.sh          nightly: a backup, then what is new (3000 write-ups per run)
#   sh scripts/refresh.sh seed     first fill: everything, including the reference collections
# Each step runs even if the one before it failed, so one source being down does not stop the rest.
cd "$(dirname "$0")/.." || exit 1
mode="${1:-nightly}"
# Import secrets, read here because a scheduled task runs through docker exec and cannot see the entrypoint's.
#   CVENOW_API_KEY_SECRET_ID: cve.now key (polling reaches back 90 days instead of 7).
#   H1_API_USERNAME_SECRET_ID, H1_API_TOKEN_SECRET_ID: the official HackerOne Hacker API, for `ingest.mjs list`.
. scripts/secrets.sh
fetch CVENOW_API_KEY "$CVENOW_API_KEY_SECRET_ID"
fetch H1_API_USERNAME "$H1_API_USERNAME_SECRET_ID"
fetch H1_API_TOKEN "$H1_API_TOKEN_SECRET_ID"
echo "== backup"; node scripts/backup.mjs || echo "!! backup failed"
if [ "$mode" = seed ]; then steps="import payloads cves cvenow subdomains logos|--max|500 details|--max|20000 index"
else steps="import details|--max|3000 index cves cvenow subdomains logos|--max|500"; fi
# With Hacker API credentials, also read the newest disclosures (the API lists them newest first; 300 is three pages)
# before the write-ups are fetched. Without them the step is left out, since list stops with an error.
if [ -n "$H1_API_USERNAME" ] && [ -n "$H1_API_TOKEN" ]; then steps="import list|--max|300 ${steps#import }"
else echo "== list skipped (no HackerOne API credentials)"; fi
for step in $steps; do
  set -- $(echo "$step" | tr '|' ' ')
  echo "== $*"; nice -n 10 node scripts/ingest.mjs "$@" || echo "!! $1 failed"
done
echo "== done $(date -u +%FT%TZ)"
