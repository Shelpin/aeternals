#!/bin/bash

# Configuration
BASE_DIR="/root/eliza"
PROCESSES_DIR="${BASE_DIR}/processes"
LOGS_DIR="${BASE_DIR}/logs"
STATE_DIR="${BASE_DIR}/state"
AUTO_RESTART=true

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $*" | tee -a "${LOGS_DIR}/current/monitor_agents.log"
}

# Function to check if a process is running
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

# Function to check port status
check_port() {
    local port=$1
    if ! lsof -i:"${port}" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Function to check Telegram connection
check_telegram_connection() {
    local log_file=$1
    local minutes=5
    
    if ! [ -f "$log_file" ]; then
        return 1
    fi
    
    # Check for recent Telegram activity
    if grep -q "Bot has been initialized" "$log_file"; then
        if tail -n 1000 "$log_file" | grep -q "$(date -d "-$minutes minutes" +"%Y-%m-%d %H:")"; then
            return 0
        fi
    fi
    return 1
}

# Function to get process memory usage
get_memory_usage() {
    local pid=$1
    if check_process "$pid"; then
        ps -o rss= -p "$pid" | awk '{print int($1/1024)}'
    else
        echo "0"
    fi
}

# Function to get process uptime
get_uptime() {
    local state_file=$1
    if [ -f "$state_file" ]; then
        local start_time
        start_time=$(jq -r '.start_time' "$state_file" 2>/dev/null)
        if [ -n "$start_time" ]; then
            local start_seconds
            start_seconds=$(date -d "$start_time" +%s)
            local now_seconds
            now_seconds=$(date +%s)
            local uptime=$((now_seconds - start_seconds))
            
            # Format uptime
            local days=$((uptime / 86400))
            local hours=$(( (uptime % 86400) / 3600 ))
            local minutes=$(( (uptime % 3600) / 60 ))
            
            if [ "$days" -gt 0 ]; then
                echo "${days}d ${hours}h ${minutes}m"
            elif [ "$hours" -gt 0 ]; then
                echo "${hours}h ${minutes}m"
            else
                echo "${minutes}m"
            fi
        fi
    fi
    echo "unknown"
}

# Function to check agent health
check_agent() {
    local character=$1
    local token_port=${AGENTS[${character}]}
    local port=${token_port#*:}
    local state_file="${STATE_DIR}/${character}.state"
    local pid_file="${PROCESSES_DIR}/pids/${character}.pid"
    local log_file="${LOGS_DIR}/current/${character}.log"
    local status_line=""
    
    # Get PID from state file or PID file
    local pid=""
    if [ -f "$state_file" ]; then
        pid=$(jq -r '.pid' "$state_file" 2>/dev/null)
    elif [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
    fi
    
    # Check process status
    if check_process "$pid"; then
        local mem_usage
        mem_usage=$(get_memory_usage "$pid")
        local uptime
        uptime=$(get_uptime "$state_file")
        
        # Check port status
        if check_port "$port"; then
            # Check Telegram connection
            if check_telegram_connection "$log_file"; then
                status_line="${GREEN}✓${NC} $character"
                status_line+=" [PID: ${pid}, Port: ${port}, Mem: ${mem_usage}MB, Uptime: ${uptime}]"
                echo -e "$status_line"
                return 0
            else
                status_line="${YELLOW}!${NC} $character"
                status_line+=" [PID: ${pid}, Port: ${port}, Mem: ${mem_usage}MB, Uptime: ${uptime}]"
                status_line+=" ${RED}(Telegram connection issue)${NC}"
            fi
        else
            status_line="${RED}✗${NC} $character"
            status_line+=" [PID: ${pid}, Port: ${port}, Mem: ${mem_usage}MB, Uptime: ${uptime}]"
            status_line+=" ${RED}(Port not listening)${NC}"
        fi
    else
        status_line="${RED}✗${NC} $character is not running"
    fi
    
    echo -e "$status_line"
    
    # Auto-restart if enabled
    if [ "$AUTO_RESTART" = true ]; then
        log "WARN" "Attempting to restart $character..."
        ./start_agents.sh "$character"
    fi
    
    return 1
}

# Function to show recent logs
show_recent_logs() {
    local character=$1
    local log_file="${LOGS_DIR}/current/${character}.log"
    
    echo -e "\n${BLUE}=== Recent logs for $character ===${NC}"
    if [ -f "$log_file" ]; then
        echo "Last 5 lines:"
        tail -n 5 "$log_file"
        
        echo -e "\nRecent errors/warnings:"
        grep -i "error\|warn" "$log_file" | tail -n 3
    else
        echo "No log file found"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [options] [agent_name1 agent_name2 ...]"
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -l, --logs        Show recent logs"
    echo "  -n, --no-restart  Disable auto-restart"
    echo "Available agents:"
    for agent in "${!AGENTS[@]}"; do
        echo "  - $agent"
    done
}

# Process options
SHOW_LOGS=false
while [[ "$1" =~ ^- ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -l|--logs)
            SHOW_LOGS=true
            shift
            ;;
        -n|--no-restart)
            AUTO_RESTART=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Monitor specified agents or all if none specified
echo -e "\n🔍 ${BLUE}Checking agent status...${NC}"
if [ $# -eq 0 ]; then
    for character in "${!AGENTS[@]}"; do
        check_agent "$character"
        if [ "$SHOW_LOGS" = true ]; then
            show_recent_logs "$character"
        fi
    done
else
    for character in "$@"; do
        if [[ -v AGENTS[$character] ]]; then
            check_agent "$character"
            if [ "$SHOW_LOGS" = true ]; then
                show_recent_logs "$character"
            fi
        else
            log "ERROR" "Unknown agent: $character"
            show_usage
        fi
    done
fi

echo -e "\n💡 ${BLUE}Tips:${NC}"
echo "- View full logs: tail -f ${LOGS_DIR}/current/<agent_name>.log"
echo "- Stop agents: ./stop_agents.sh"
echo "- Restart all: ./stop_agents.sh && ./start_agents.sh"
echo "- Monitor with logs: $0 -l"
echo "- Monitor specific agent: $0 <agent_name>"
