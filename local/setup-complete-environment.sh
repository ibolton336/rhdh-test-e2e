#!/bin/bash

# Complete Environment Setup Script for RHDH + MTA Local Development
# This script automates the entire setup process

set -e

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=()
    
    command -v docker >/dev/null 2>&1 || command -v podman >/dev/null 2>&1 || missing+=("docker/podman")
    command -v minikube >/dev/null 2>&1 || missing+=("minikube")
    command -v kubectl >/dev/null 2>&1 || missing+=("kubectl")
    command -v node >/dev/null 2>&1 || missing+=("node")
    command -v npm >/dev/null 2>&1 || missing+=("npm")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v ngrok >/dev/null 2>&1 || missing+=("ngrok")
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing prerequisites: ${missing[*]}"
        log_info "Please install missing tools and try again"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Step 1: Setup Minikube and Konveyor
setup_minikube_konveyor() {
    log_info "=== Phase 1: Setting up Minikube and Konveyor ==="
    
    # Check if Minikube is already running
    if minikube status >/dev/null 2>&1; then
        log_warning "Minikube is already running. Skipping start."
    else
        log_info "Configuring and starting Minikube..."
        minikube config set memory 10240
        minikube config set cpus 4
        minikube start --addons=dashboard --addons=ingress
    fi
    
    # Install OLM
    log_info "Installing Operator Lifecycle Manager..."
    if [ ! -f "install.sh" ]; then
        curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.28.0/install.sh -o install.sh
        chmod +x install.sh
    fi
    ./install.sh v0.28.0
    
    # Install Konveyor
    log_info "Installing Konveyor operator with authentication..."
    if [ ! -f "setup-operator.sh" ]; then
        curl https://raw.githubusercontent.com/konveyor/tackle2-ui/main/hack/setup-operator.sh -o setup-operator.sh
        chmod +x setup-operator.sh
    fi
    export FEATURE_AUTH_REQUIRED=true
    ./setup-operator.sh
    
    # Wait for pods to be ready
    log_info "Waiting for Konveyor pods to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=tackle -n konveyor-tackle --timeout=300s || true
    
    log_success "Minikube and Konveyor setup complete"
}

# Step 2: Setup tackle2-ui development
setup_tackle2_ui() {
    log_info "=== Phase 2: Setting up tackle2-ui development ==="
    
    TACKLE_DIR="$HOME/Development/tackle2-ui"
    
    if [ ! -d "$TACKLE_DIR" ]; then
        log_info "Cloning tackle2-ui repository..."
        mkdir -p "$HOME/Development"
        cd "$HOME/Development"
        git clone https://github.com/konveyor/tackle2-ui.git
    fi
    
    cd "$TACKLE_DIR"
    
    log_info "Installing dependencies..."
    npm install
    
    log_info "Starting tackle2-ui development server..."
    export AUTH_REQUIRED=true
    
    # Start in background
    nohup npm run start:dev > tackle2-ui.log 2>&1 &
    echo $! > tackle2-ui.pid
    
    log_success "tackle2-ui development server started (check tackle2-ui.log for details)"
    
    # Return to original directory
    cd - > /dev/null
}

# Step 3: Create Keycloak client
create_keycloak_client() {
    log_info "=== Phase 3: Creating Keycloak client ==="
    
    # Wait a bit for Keycloak to be fully ready
    sleep 10
    
    if [ -f "tackle-create-keycloak-client-fixed.sh" ]; then
        log_info "Running Keycloak client creation script..."
        ./tackle-create-keycloak-client-fixed.sh
        log_success "Keycloak client created"
    else
        log_error "tackle-create-keycloak-client-fixed.sh not found!"
        return 1
    fi
}

# Step 4: Setup ngrok tunnel
setup_ngrok() {
    log_info "=== Phase 4: Setting up ngrok tunnel ==="
    
    if [ -f "ngrok-tunnel.sh" ]; then
        log_info "Starting ngrok tunnel..."
        ./ngrok-tunnel.sh start
        
        # Get and display the URL
        sleep 3
        NGROK_URL=$(./ngrok-tunnel.sh url)
        
        if [ -n "$NGROK_URL" ]; then
            # Export for use in other functions
            export NGROK_URL
            
            log_success "Ngrok tunnel started"
            echo
            echo "============================================"
            echo "NGROK URL: $NGROK_URL"
            echo "============================================"
            echo
        else
            log_error "Failed to get ngrok URL"
            return 1
        fi
    else
        log_error "ngrok-tunnel.sh not found!"
        return 1
    fi
}

# Step 5: Setup rhdh-local
setup_rhdh_local() {
    log_info "=== Phase 5: Setting up rhdh-local ==="
    
    RHDH_LOCAL_DIR="$HOME/Development/rhdh-local"
    
    # Clone rhdh-local if it doesn't exist
    if [ ! -d "$RHDH_LOCAL_DIR" ]; then
        log_info "Cloning rhdh-local repository..."
        mkdir -p "$HOME/Development"
        cd "$HOME/Development"
        git clone https://github.com/redhat-developer/rhdh-local.git
    fi
    
    cd "$RHDH_LOCAL_DIR"
    
    # Copy configuration files
    log_info "Copying configuration files..."
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    if [ -f "$SCRIPT_DIR/app-config.local.yaml" ]; then
        cp "$SCRIPT_DIR/app-config.local.yaml" ./
        log_success "Copied app-config.local.yaml"
    fi
    
    if [ -f "$SCRIPT_DIR/dynamic-plugins.override.yaml" ]; then
        cp "$SCRIPT_DIR/dynamic-plugins.override.yaml" ./
        log_success "Copied dynamic-plugins.override.yaml"
    fi
    
    # Update the ngrok URL in app-config.local.yaml
    if [ -n "$NGROK_URL" ] && [ -f "app-config.local.yaml" ]; then
        log_info "Updating app-config.local.yaml with ngrok URL..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|https://YOUR-NGROK-URL.ngrok-free.dev|$NGROK_URL|g" app-config.local.yaml
        else
            # Linux
            sed -i "s|https://YOUR-NGROK-URL.ngrok-free.dev|$NGROK_URL|g" app-config.local.yaml
        fi
        log_success "Updated MTA URL to: $NGROK_URL"
    fi
    
    # Start rhdh-local
    log_info "Starting rhdh-local..."
    if command -v podman &> /dev/null; then
        podman compose up -d
    else
        docker compose up -d
    fi
    
    log_success "rhdh-local started successfully"
    
    # Return to original directory
    cd - > /dev/null
}

# Step 6: Show next steps
show_next_steps() {
    log_info "=== Setup Complete! ==="
    echo
    echo "✅ All services are now running!"
    echo
    echo "Service URLs:"
    echo "- RHDH: http://localhost:7007 (login as 'Guest')"
    echo "- tackle2-ui dev: http://localhost:9003"
    echo "- Hub API: http://localhost:9000"
    echo "- Keycloak: http://localhost:9001/auth"
    echo "- Ngrok dashboard: http://localhost:4040"
    echo
    echo "To check status:"
    echo "- Konveyor pods: kubectl get pods -n konveyor-tackle"
    echo "- Ngrok tunnel: ./ngrok-tunnel.sh status"
    echo "- RHDH logs: podman compose logs rhdh --tail 20 (or docker compose logs)"
    echo
    echo "To restart RHDH after config changes:"
    echo "- podman compose stop rhdh && podman compose start rhdh"
    echo
    echo "The MTA plugin should now be visible in service entities in the RHDH catalog."
}

# Main execution
main() {
    log_info "Starting complete environment setup..."
    
    check_prerequisites
    
    # Execute setup steps
    setup_minikube_konveyor
    setup_tackle2_ui
    
    # Wait for services to be ready
    log_info "Waiting for services to initialize..."
    sleep 30
    
    create_keycloak_client
    setup_ngrok
    
    # Setup rhdh-local with the ngrok URL
    setup_rhdh_local
    
    show_next_steps
}

# Handle cleanup on exit
cleanup() {
    if [ -f "tackle2-ui.pid" ]; then
        log_info "Stopping tackle2-ui server..."
        kill $(cat tackle2-ui.pid) 2>/dev/null || true
        rm -f tackle2-ui.pid
    fi
}

trap cleanup EXIT

# Run main function
main "$@"
