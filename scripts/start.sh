#starter script
#!/bin/bash
set -e

# 1. Validate required inputs
if [ -z "${AZP_URL}" ]; then
  echo >&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "${AZP_TOKEN_FILE}" ]; then
  if [ -z "${AZP_TOKEN}" ]; then
    echo >&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  AZP_TOKEN_FILE="/azp/.token"
  echo -n "${AZP_TOKEN}" > "${AZP_TOKEN_FILE}"
fi

unset AZP_TOKEN  # for security

# 2. Optional working directory
if [ -n "${AZP_WORK}" ]; then
  mkdir -p "${AZP_WORK}"
fi

# 3. Cleanup on exit
cleanup() {
  trap "" EXIT
  if [ -e ./config.sh ]; then
    echo "Cleanup: removing agent registration..."
    while true; do
      ./config.sh remove --unattended --auth PAT --token "$(cat "${AZP_TOKEN_FILE}")" && break
      echo "Retrying removal in 30s..."
      sleep 30
    done
  fi
}

trap "cleanup; exit 0" EXIT
trap "cleanup; exit 130" INT
trap "cleanup; exit 143" TERM

# 4. Logging function
log() {
  echo -e "\033[1;36m$1\033[0m"
}

# 5. Ignore these env vars during agent startup
export VSO_AGENT_IGNORE="AZP_TOKEN,AZP_TOKEN_FILE"

# 6. Download latest matching agent
log "1. Getting latest Azure Pipelines agent for: ${TARGETARCH}"

AZP_AGENT_PACKAGES=$(curl -LsS \
  -u user:"$(cat "${AZP_TOKEN_FILE}")" \
  -H "Accept:application/json" \
  "${AZP_URL}/_apis/distributedtask/packages/agent?platform=${TARGETARCH}&top=1")

AZP_AGENT_URL=$(echo "${AZP_AGENT_PACKAGES}" | jq -r ".value[0].downloadUrl")

if [ -z "${AZP_AGENT_URL}" ] || [ "${AZP_AGENT_URL}" = "null" ]; then
  echo >&2 "error: couldn't fetch Azure Pipelines agent for TARGETARCH=${TARGETARCH}"
  exit 1
fi

log "2. Downloading and extracting Azure Pipelines agent..."
curl -LsS "${AZP_AGENT_URL}" | tar -xz

# 7. Source environment (env.sh)
source ./env.sh

# 8. Configure agent
log "3. Configuring agent..."
./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "${AZP_URL}" \
  --auth PAT \
  --token "$(cat "${AZP_TOKEN_FILE}")" \
  --pool "${AZP_POOL:-Default}" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula

# 9. Run agent
log "4. Running agent..."
chmod +x ./run.sh
./run.sh "$@" & wait $!
azureuser@agent-vm:~/agent-setup$ 
