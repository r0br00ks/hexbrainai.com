#!/bin/sh
# Data refresh for the container. Run by hand or from a Coolify scheduled task:
#   sh scripts/refresh.sh          nightly: a backup, then what is new (3000 write-ups per run)
#   sh scripts/refresh.sh seed     first fill: everything, including the reference collections
# Each step runs even if the one before it failed, so one source being down does not stop the rest.
cd "$(dirname "$0")/.." || exit 1
mode="${1:-nightly}"
echo "== backup"; node scripts/backup.mjs || echo "!! backup failed"
if [ "$mode" = seed ]; then steps="import payloads cves cvenow subdomains logos|--max|500 details|--max|20000 index"
else steps="import details|--max|3000 index cves cvenow subdomains logos|--max|500"; fi
for step in $steps; do
  set -- $(echo "$step" | tr '|' ' ')
  echo "== $*"; nice -n 10 node scripts/ingest.mjs "$@" || echo "!! $1 failed"
done
echo "== done $(date -u +%FT%TZ)"
