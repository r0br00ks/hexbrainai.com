# Sourced by docker-entrypoint.sh and scripts/refresh.sh. Defines fetch, which reads one Bitwarden secret into a variable.
# Needs BWS_ACCESS_TOKEN in the environment; Coolify carries that token and the secret ids, never the values.
# A refresh started with docker exec (a Coolify scheduled task) does not see what the entrypoint exported, so
# refresh.sh reads its own secrets with this same function.
fetch() { # $1 = variable to set, $2 = Bitwarden secret id
  [ -n "$2" ] || return 0
  [ -n "$BWS_ACCESS_TOKEN" ] || return 0
  v=$(bws secret get "$2" 2>/dev/null | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.parse(s).value||"")}catch{}})')
  if [ -n "$v" ]; then export "$1=$v"; else echo "secrets: could not read secret for $1" >&2; fi
  unset v
}
