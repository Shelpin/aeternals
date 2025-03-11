#!/bin/bash

# Configuration
BASE_DIR="/root/eliza"
PROCESSES_DIR="${BASE_DIR}/processes"
LOGS_DIR="${BASE_DIR}/logs"
STATE_DIR="${BASE_DIR}/state"

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $*" | tee -a "${LOGS_DIR}/current/stop_agents.log"
}

# Function to check if a process is still running
check_process() {
    local pid=$1
    if [ -z "$pid" ]; then
        return 1
    fi
    if ! ps -p "$pid" > /dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Function to gracefully stop a process
stop_process() {
    local pid=$1
    local timeout=30
    local count=0
    
    kill -15 "$pid" 2>/dev/null
    while check_process "$pid" && [ $count -lt $timeout ]; do
        sleep 1
        ((count++))
    done
    
    if check_process "$pid"; then
        kill -9 "$pid" 2>/dev/null
        sleep 1
    fi
    
    if check_process "$pid"; then
        return 1
    fi
    return 0
}

# Function to clean up agent resources
cleanup_agent() {
    local character=$1
    rm -f "${PROCESSES_DIR}/pids/${character}.pid"
    rm -f "${PROCESSES_DIR}/ports/${character}.port"
    rm -rf "${PROCESSES_DIR}/locks/${character}.lock"
    rm -f "${STATE_DIR}/${character}.state"
}

# Function to stop individual agent
stop_agent() {
    local character=$1
    local found_process=false
    log "INFO" "Stopping ${character}..."
    
    # Check state file first
    local state_file="${STATE_DIR}/${character}.state"
    if [ -f "$state_file" ]; then
        local pid
        pid=$(jq -r '.pid' "$state_file" 2>/dev/null)
        if check_process "$pid"; then
            log "INFO" "Stopping ${character} (PID: ${pid}) from state file"
            if stop_process "$pid"; then
                found_process=true
                log "INFO" "Successfully stopped ${character}"
            else
                log "WARN" "Failed to stop ${character} gracefully"
            fi
        fi
    fi
    
    # Check PID file
    local pid_file="${PROCESSES_DIR}/pids/${character}.pid"
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        if check_process "$pid"; then
            log "INFO" "Stopping ${character} (PID: ${pid}) from PID file"
            if stop_process "$pid"; then
                found_process=true
                log "INFO" "Successfully stopped ${character}"
            else
                log "WARN" "Failed to stop ${character} gracefully"
            fi
        fi
    fi
    
    # Find any remaining processes by character name
    local remaining_pids
    remaining_pids=$(ps aux | grep "characters/${character}.json" | grep -v grep | awk '{print $2}')
    if [ -n "$remaining_pids" ]; then
        for pid in $remaining_pids; do
            log "INFO" "Stopping additional ${character} process (PID: ${pid})"
            if stop_process "$pid"; then
                found_process=true
                log "INFO" "Successfully stopped additional process"
            else
                log "WARN" "Failed to stop additional process gracefully"
            fi
        done
    fi
    
    # Clean up resources
    cleanup_agent "$character"
    
    if [ "$found_process" = false ]; then
        log "INFO" "No running processes found for ${character}"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [options] [agent_name1 agent_name2 ...]"
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --force    Force kill agents"
    echo "Available agents:"
    for agent in "${!AGENTS[@]}"; do
        echo "  - $agent"
    done
}

# Process options
FORCE=false
while [[ "$1" =~ ^- ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Stop specified agents or all if none specified
if [ $# -eq 0 ]; then
    log "INFO" "Stopping all agents..."
    for character in "${!AGENTS[@]}"; do
        stop_agent "$character"
    done
else
    for character in "$@"; do
        if [[ -v AGENTS[$character] ]]; then
            stop_agent "$character"
        else
            log "ERROR" "Unknown agent: $character"
            show_usage
        fi
    done
fi

log "INFO" "Stop script completed"