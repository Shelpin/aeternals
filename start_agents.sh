#!/bin/bash

# Configuration
BASE_DIR="/root/eliza"
PROCESSES_DIR="${BASE_DIR}/processes"
LOGS_DIR="${BASE_DIR}/logs"
STATE_DIR="${BASE_DIR}/state"

# Ensure directories exist
mkdir -p "${PROCESSES_DIR}"/{locks,pids,ports} "${LOGS_DIR}"/{archive,current} "${STATE_DIR}"

# Log rotation settings
ROTATE_SIZE="100M"
ROTATE_COUNT=5

# Port range for agents
PORT_START=3000
PORT_END=3005

# Agent definitions with base ports
declare -A AGENTS=(
    ["bitcoin_maxi_420"]="TELEGRAM_BOT_TOKEN_BitcoinMaxi420:3000"
    ["eth_memelord_9000"]="TELEGRAM_BOT_TOKEN_ETHMemeLord9000:3001"
    ["code_samurai_77"]="TELEGRAM_BOT_TOKEN_CodeSamurai77:3002"
    ["bag_flipper_9000"]="TELEGRAM_BOT_TOKEN_BagFlipper9000:3003"
    ["vc_shark_99"]="TELEGRAM_BOT_TOKEN_VCShark99:3004"
    ["linda_evangelista_88"]="TELEGRAM_BOT_TOKEN_LindAEvangelista88:3005"
)

# Function to log messages with timestamps
log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $*" | tee -a "${LOGS_DIR}/current/start_agents.log"
}

# Function to check if a port is available
check_port() {
    local port=$1
    if lsof -i:"${port}" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Function to acquire a process lock
acquire_lock() {
    local agent=$1
    local lock_file="${PROCESSES_DIR}/locks/${agent}.lock"
    
    if ! mkdir "${lock_file}" 2>/dev/null; then
        local lock_pid
        if [[ -f "${lock_file}/pid" ]]; then
            lock_pid=$(cat "${lock_file}/pid")
            if ! ps -p "${lock_pid}" > /dev/null 2>&1; then
                log "WARN" "Stale lock found for ${agent}, cleaning up"
                rm -rf "${lock_file}"
                mkdir "${lock_file}"
            else
                return 1
            fi
        else
            return 1
        fi
    fi
    echo $$ > "${lock_file}/pid"
    return 0
}

# Function to release a process lock
release_lock() {
    local agent=$1
    rm -rf "${PROCESSES_DIR}/locks/${agent}.lock"
}

# Function to start individual agent
start_agent() {
    local character=$1
    local token_port=${AGENTS[${character}]}
    local token_var=${token_port%:*}
    local port=${token_port#*:}
    
    log "INFO" "Starting ${character} on port ${port}..."
    
    # Check if agent is already running
    if ! acquire_lock "${character}"; then
        log "ERROR" "${character} is already running or locked"
        return 1
    fi
    
    # Check port availability
    if ! check_port "${port}"; then
        log "ERROR" "Port ${port} is already in use"
        release_lock "${character}"
        return 1
    fi
    
    # Source NVM and set up Node environment
    export NVM_DIR="/root/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Source the main .env file to get all variables
    set -a
    source "${BASE_DIR}/.env"
    set +a
    
    # Get the token value
    local token_value="${!token_var}"
    if [ -z "${token_value}" ]; then
        log "ERROR" "Token not found for ${character}"
        release_lock "${character}"
        return 1
    fi
    
    # Start the agent with output going to both terminal and log file
    local log_file="${LOGS_DIR}/current/${character}.log"
    local pid_file="${PROCESSES_DIR}/pids/${character}.pid"
    
    # Create a clean environment file for this agent
    local temp_env="${PROCESSES_DIR}/${character}.env"
    {
        echo "export NODE_ENV=production"
        echo "export NVM_DIR=/root/.nvm"
        echo "export PATH=/root/.nvm/versions/node/v23.3.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        echo "export HOME=/root"
        echo "export PORT=${port}"
        echo "export TELEGRAM_BOT_TOKEN=${token_value}"
        # Add other required variables from .env but skip any existing TELEGRAM_BOT_TOKEN entries
        grep -v '^TELEGRAM_BOT_TOKEN' "${BASE_DIR}/.env" | grep -v '^#' | grep -v '^$' | sed 's/^/export /'
    } > "${temp_env}"
    
    # Start agent with proper logging and environment
    cd "${BASE_DIR}/agent" && \
    bash -c "source ${temp_env} && \
    source \$NVM_DIR/nvm.sh && \
    nvm use v23.3.0 && \
    pnpm start \
        --isRoot \
        --characters='../characters/${character}.json' \
        --clients=@elizaos-plugins/client-telegram \
        --update-env \
        --log-level=debug" > >(tee -a "${log_file}") 2>&1 &
    
    local pid=$!
    echo "${pid}" > "${pid_file}"
    echo "${port}" > "${PROCESSES_DIR}/ports/${character}.port"
    
    # Wait a moment to check if process is still running
    sleep 5
    if ! ps -p "${pid}" > /dev/null 2>&1; then
        log "ERROR" "Agent ${character} failed to start"
        rm -f "${temp_env}"
        release_lock "${character}"
        return 1
    fi
    
    # Check Telegram connection
    local retries=0
    local max_retries=12
    local connected=false
    
    while [ $retries -lt $max_retries ]; do
        if grep -q "Bot has been initialized" "${log_file}"; then
            connected=true
            break
        fi
        sleep 5
        ((retries++))
    done
    
    if [ "$connected" = true ]; then
        log "INFO" "${character} successfully started and connected to Telegram (PID: ${pid})"
    else
        log "WARN" "${character} started but Telegram connection not confirmed"
    fi
    
    # Create state file
    cat > "${STATE_DIR}/${character}.state" << EOF
{
    "pid": ${pid},
    "port": ${port},
    "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "token_var": "${token_var}",
    "log_file": "${log_file}",
    "env_file": "${temp_env}"
}
EOF
    
    return 0
}

# Function to setup log rotation
setup_log_rotation() {
    cat > /etc/logrotate.d/eliza_agents << EOF
${LOGS_DIR}/current/*.log {
    size ${ROTATE_SIZE}
    rotate ${ROTATE_COUNT}
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        mv ${LOGS_DIR}/current/*.gz ${LOGS_DIR}/archive/ 2>/dev/null || true
    endscript
}
EOF
}

# Show usage information
show_usage() {
    echo "Usage: $0 [agent_name1 agent_name2 ...]"
    echo "Available agents:"
    for agent in "${!AGENTS[@]}"; do
        echo "  - $agent"
    done
    echo "Examples:"
    echo "  $0                          # Start all agents"
    echo "  $0 bitcoin_maxi_420        # Start only BTCMaxi"
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Setup log rotation
setup_log_rotation

# Start specified agents or all if none specified
if [ $# -eq 0 ]; then
    log "INFO" "Starting all agents..."
    for character in "${!AGENTS[@]}"; do
        start_agent "$character"
    done
else
    for character in "$@"; do
        if [[ -v AGENTS[$character] ]]; then
            start_agent "$character"
        else
            log "ERROR" "Unknown agent: $character"
            show_usage
        fi
    done
fi

log "INFO" "Start script completed. Use './monitor_agents.sh' to check status"