#!/bin/bash
# ================================================================
# VulnCorp Lab — Tunnel Management Script
# ================================================================
# Manages ngrok tunnels separately from the Docker lab.
# Use this to restart tunnels, check status, or stop them.
#
# USAGE:
#   sudo ./tunnel.sh start     # Start tunnels
#   sudo ./tunnel.sh stop      # Stop tunnels
#   sudo ./tunnel.sh status    # Show current tunnel URLs
#   sudo ./tunnel.sh restart   # Restart tunnels
# ================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.ngrok_pid"
TUNNEL_CONFIG="$SCRIPT_DIR/ngrok-vulncorp.yml"

log_info()  { echo -e "${GREEN}[+]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

get_tunnels() {
    local TUNNELS=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
    if [ -z "$TUNNELS" ] || [ "$TUNNELS" = "null" ]; then
        return 1
    fi

    echo "$TUNNELS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tunnels = data.get('tunnels', [])
if not tunnels:
    print('No active tunnels')
    sys.exit(0)
for t in tunnels:
    name = t.get('name', 'unknown')
    url = t.get('public_url', 'N/A')
    proto = t.get('proto', '?')
    addr = t.get('config', {}).get('addr', '?')
    print(f'  {name:20s} {proto:6s} {url} -> {addr}')
" 2>/dev/null
}

start_tunnels() {
    # Check if ngrok is installed
    if ! command -v ngrok &> /dev/null; then
        log_error "ngrok is not installed. Run deploy.sh first."
        exit 1
    fi

    # Check if already running
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            log_warn "ngrok is already running (PID: $OLD_PID)"
            log_info "Use './tunnel.sh status' to see URLs, or './tunnel.sh restart' to restart"
            return 0
        fi
    fi

    # Create tunnel config if missing
    if [ ! -f "$TUNNEL_CONFIG" ]; then
        cat > "$TUNNEL_CONFIG" << NEOF
version: 2
tunnels:
  vulncorp-web:
    proto: http
    addr: 8080
    inspect: false
  vulncorp-ftp:
    proto: tcp
    addr: 2121
NEOF
    fi

    log_info "Starting ngrok tunnels..."

    # Start ngrok
    NGROK_MAIN_CONFIG=$(ngrok config check 2>&1 | grep -oP '(?<=at ).*(?=is valid)' || echo "")

    if [ -n "$NGROK_MAIN_CONFIG" ]; then
        ngrok start --config "$NGROK_MAIN_CONFIG" --config "$TUNNEL_CONFIG" --all &
    else
        ngrok start --config "$TUNNEL_CONFIG" --all &
    fi

    NGROK_PID=$!
    echo "$NGROK_PID" > "$PID_FILE"

    sleep 4
    log_info "Tunnels started (PID: $NGROK_PID)"
    echo ""
    log_info "Active tunnels:"
    get_tunnels || log_warn "Could not fetch tunnel info. Check http://localhost:4040"
    echo ""
    echo -e "  ${BOLD}ngrok Dashboard:${NC} ${GREEN}http://localhost:4040${NC}"
}

stop_tunnels() {
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            kill "$OLD_PID"
            log_info "Stopped ngrok (PID: $OLD_PID)"
        else
            log_warn "ngrok process $OLD_PID is not running"
        fi
        rm -f "$PID_FILE"
    else
        # Try to kill any ngrok process
        if pkill ngrok 2>/dev/null; then
            log_info "Stopped ngrok process(es)"
        else
            log_warn "No ngrok process found"
        fi
    fi
}

show_status() {
    echo ""
    echo -e "${BOLD}  ngrok Tunnel Status${NC}"
    echo -e "  ─────────────────────────────────"

    if get_tunnels; then
        echo ""
        echo -e "  ${BOLD}Dashboard:${NC} ${GREEN}http://localhost:4040${NC}"
    else
        log_warn "No active tunnels. Start them with: ./tunnel.sh start"
    fi
    echo ""
}

# ── Main ─────────────────────────────────────────────────────────

ACTION="${1:-start}"

case $ACTION in
    start)
        start_tunnels
        ;;
    stop)
        stop_tunnels
        ;;
    restart)
        stop_tunnels
        sleep 2
        start_tunnels
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
