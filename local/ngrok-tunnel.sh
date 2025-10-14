#!/bin/bash

# ngrok-tunnel.sh - Manage ngrok tunnel for port 9000
# Usage: ./ngrok-tunnel.sh [start|stop|status|url|restart] [--with-host-header]

set -e

PORT=${NGROK_PORT:-9000}
NGROK_API="http://localhost:4040/api/tunnels"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if ngrok is running
is_ngrok_running() {
    if pgrep -f "ngrok.*http.*$PORT" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Get tunnel URL
get_tunnel_url() {
    if curl -s "$NGROK_API" > /dev/null 2>&1; then
        curl -s "$NGROK_API" | jq -r '.tunnels[0].public_url // empty' 2>/dev/null
    else
        echo ""
    fi
}

# Get tunnel info
get_tunnel_info() {
    if curl -s "$NGROK_API" > /dev/null 2>&1; then
        curl -s "$NGROK_API" | jq '.tunnels[] | {name, public_url, config}' 2>/dev/null
    else
        echo "ngrok API not accessible"
    fi
}

# Start tunnel
start_tunnel() {
    local with_host_header=$1

    if is_ngrok_running; then
        log_warning "ngrok tunnel is already running"
        show_status
        return 0
    fi

    log_info "Starting ngrok tunnel on port $PORT..."

    if [[ "$with_host_header" == "true" ]]; then
        log_warning "Starting with --host-header=localhost:$PORT (may break OAuth)"
        nohup ngrok http $PORT --host-header=localhost:$PORT > /dev/null 2>&1 &
    else
        log_info "Starting without host header (configure app to accept ngrok domain)"
        nohup ngrok http $PORT > /dev/null 2>&1 &
    fi

    # Wait for tunnel to start
    log_info "Waiting for tunnel to initialize..."
    sleep 3

    if is_ngrok_running; then
        local url=$(get_tunnel_url)
        if [[ -n "$url" ]]; then
            log_success "Tunnel started successfully!"
            echo
            echo "🌐 Public URL: $url"
            echo "📊 Dashboard: http://localhost:4040"
            echo "🔧 Local: http://localhost:$PORT"
            echo

            # Save URL to file for easy access
            echo "$url" > .ngrok_url
            log_info "Tunnel URL saved to .ngrok_url"
        else
            log_error "Tunnel process started but URL not available"
        fi
    else
        log_error "Failed to start ngrok tunnel"
        return 1
    fi
}

# Stop tunnel
stop_tunnel() {
    if ! is_ngrok_running; then
        log_warning "ngrok tunnel is not running"
        return 0
    fi

    log_info "Stopping ngrok tunnel..."
    pkill -f "ngrok.*http.*$PORT" || true

    # Clean up
    rm -f .ngrok_url

    sleep 1

    if ! is_ngrok_running; then
        log_success "Tunnel stopped successfully"
    else
        log_error "Failed to stop tunnel"
        return 1
    fi
}

# Show status
show_status() {
    if is_ngrok_running; then
        log_success "ngrok tunnel is running"
        local url=$(get_tunnel_url)
        if [[ -n "$url" ]]; then
            echo "Public URL: $url"
            echo "Dashboard: http://localhost:4040"
        fi
        echo
        log_info "Tunnel details:"
        get_tunnel_info
    else
        log_warning "ngrok tunnel is not running"
    fi
}

# Show URL only
show_url() {
    local url=$(get_tunnel_url)
    if [[ -n "$url" ]]; then
        echo "$url"
    else
        log_error "No tunnel running or URL not available"
        return 1
    fi
}

# Restart tunnel
restart_tunnel() {
    local with_host_header=$1
    log_info "Restarting ngrok tunnel..."
    stop_tunnel
    sleep 2
    start_tunnel "$with_host_header"
}

# Show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  start             Start ngrok tunnel"
    echo "  stop              Stop ngrok tunnel"
    echo "  status            Show tunnel status"
    echo "  url               Show tunnel URL only"
    echo "  restart           Restart tunnel"
    echo
    echo "Options:"
    echo "  --with-host-header    Use --host-header=localhost:$PORT (fixes 403 but breaks OAuth)"
    echo
    echo "Environment Variables:"
    echo "  NGROK_PORT           Port to tunnel (default: 9000)"
    echo
    echo "Examples:"
    echo "  $0 start                    # Start basic tunnel"
    echo "  $0 start --with-host-header # Start with host header rewrite"
    echo "  $0 stop                     # Stop tunnel"
    echo "  $0 url                      # Get tunnel URL"
    echo
}

# Check if jq is available
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Install with: brew install jq"
    exit 1
fi

# Check if ngrok is available
if ! command -v ngrok &> /dev/null; then
    log_error "ngrok is required but not installed. Install with: brew install ngrok"
    exit 1
fi

# Parse arguments
COMMAND=${1:-status}
WITH_HOST_HEADER=false

if [[ "$2" == "--with-host-header" ]] || [[ "$1" == "--with-host-header" ]]; then
    WITH_HOST_HEADER=true
fi

# Execute command
case $COMMAND in
    start)
        start_tunnel "$WITH_HOST_HEADER"
        ;;
    stop)
        stop_tunnel
        ;;
    status)
        show_status
        ;;
    url)
        show_url
        ;;
    restart)
        restart_tunnel "$WITH_HOST_HEADER"
        ;;
    -h|--help|help)
        show_usage
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        echo
        show_usage
        exit 1
        ;;
esac