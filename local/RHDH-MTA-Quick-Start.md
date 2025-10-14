# RHDH + MTA Local Development Quick Start

This is a condensed version of the full walkthrough for experienced users who want to get up and running quickly.

## Prerequisites Checklist

- [ ] Docker/Podman installed
- [ ] Minikube installed and configured (10GB RAM, 4 CPUs)
- [ ] kubectl configured
- [ ] Node.js 18+ and npm
- [ ] ngrok account and authtoken configured
- [ ] macOS: `brew install coreutils jq ngrok`

## Quick Setup Commands

### 1. Start Everything

```bash
# Clone this repo if you haven't already
git clone <this-repo> && cd rhdh-test-e2e/local

# Run the automated setup (Minikube + Konveyor)
./start-tackle2-ui-dev.sh

# Wait for all pods to be ready
watch kubectl get pods -n konveyor-tackle
```

### 2. Start Local Development

In a new terminal:

```bash
cd ~/Development/tackle2-ui
export AUTH_REQUIRED=true
npm run start:dev
```

### 3. Create Keycloak Client

In another terminal:

```bash
cd /path/to/rhdh-test-e2e/local
./tackle-create-keycloak-client-fixed.sh
```

### 4. Start Ngrok Tunnel

```bash
./ngrok-tunnel.sh start
# Note the public URL displayed
```

### 5. Configure and Start RHDH

Clone rhdh-local and configure:

```bash
# Clone official rhdh-local
git clone https://github.com/redhat-developer/rhdh-local.git
cd rhdh-local

# Copy configuration files
cp /path/to/rhdh-test-e2e/local/app-config.local.yaml ./
cp /path/to/rhdh-test-e2e/local/dynamic-plugins.override.yaml ./

# Update ngrok URL in app-config.local.yaml
# Replace https://YOUR-NGROK-URL.ngrok-free.dev with your actual ngrok URL
```

Start RHDH:

```bash
# Podman (recommended)
podman compose up -d

# Or Docker
docker compose up -d
```

## Verification

- tackle2-ui: http://localhost:9003
- RHDH: http://localhost:7007
- Keycloak: http://localhost:9001/auth
- Ngrok dashboard: http://localhost:4040

## Common Commands

```bash
# Check status
kubectl get pods -n konveyor-tackle
./ngrok-tunnel.sh status
podman compose logs rhdh --tail 20  # or docker compose logs

# Restart services
./ngrok-tunnel.sh restart
podman compose stop rhdh && podman compose start rhdh  # or docker compose

# Clean up
minikube stop
./ngrok-tunnel.sh stop
podman compose down --volumes  # or docker compose
```

## Troubleshooting Quick Fixes

```bash
# Pods not starting
kubectl delete pod -n konveyor-tackle --all

# Auth issues
kubectl rollout restart deployment/tackle-keycloak-sso -n konveyor-tackle

# Ngrok issues
./ngrok-tunnel.sh restart

# RHDH connection issues
docker compose restart rhdh
```

For detailed explanations, see the [full walkthrough](RHDH-MTA-Local-Development-Walkthrough.md).
