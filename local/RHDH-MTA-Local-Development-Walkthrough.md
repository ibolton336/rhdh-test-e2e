# Red Hat Developer Hub (RHDH) + Migration Toolkit for Applications (MTA) Local Development Walkthrough

This comprehensive guide walks you through setting up a complete local development environment for Red Hat Developer Hub (RHDH) integrated with the Migration Toolkit for Applications (MTA/Konveyor) using Minikube.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Phase 1: Minikube and Konveyor Setup](#phase-1-minikube-and-konveyor-setup)
4. [Phase 2: Local Development Environment](#phase-2-local-development-environment)
5. [Phase 3: Ngrok Tunnel Setup](#phase-3-ngrok-tunnel-setup)
6. [Phase 4: Keycloak Client Configuration](#phase-4-keycloak-client-configuration)
7. [Phase 5: RHDH Configuration and Launch](#phase-5-rhdh-configuration-and-launch)
8. [Verification Steps](#verification-steps)
9. [Troubleshooting](#troubleshooting)
10. [Quick Reference](#quick-reference)

## Overview

This setup enables you to:
- Run Konveyor/MTA locally on Minikube with authentication enabled
- Develop tackle2-ui locally with hot-reload capabilities
- Expose your local MTA instance via ngrok for external access
- Integrate MTA with Red Hat Developer Hub (RHDH/Backstage)
- Test MTA plugins and templates in RHDH

### Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Minikube      │     │  Local Dev       │     │     RHDH         │
│                 │     │                  │     │                  │
│ ┌─────────────┐ │     │ ┌──────────────┐ │     │ ┌──────────────┐ │
│ │  Konveyor   │ │     │ │ tackle2-ui   │ │     │ │  MTA Plugin  │ │
│ │  Operator   │ │     │ │  (port 9000) │ │     │ │              │ │
│ └─────────────┘ │     │ └──────────────┘ │     │ └──────────────┘ │
│                 │     │                  │     │                  │
│ ┌─────────────┐ │     │ ┌──────────────┐ │     │                  │
│ │  Keycloak   │◄├─────┤►│    ngrok     │◄├─────┤►   Backstage    │
│ │ (port 9001) │ │     │ │  tunnel      │ │     │   (port 7007)   │
│ └─────────────┘ │     │ └──────────────┘ │     │                  │
└─────────────────┘     └──────────────────┘     └──────────────────┘
```

## Prerequisites

Before starting, ensure you have the following installed:

- **Docker** or **Podman** (for container runtime)
- **Minikube** (latest version)
- **kubectl** (Kubernetes CLI)
- **Node.js** (v18+ recommended)
- **npm** or **yarn**
- **Homebrew** (for macOS users)
- **jq** (JSON processor)
- **curl**
- **Git**
- **ngrok account** (free tier is sufficient)

### macOS Additional Requirements

```bash
brew install coreutils jq ngrok
```

## Phase 1: Minikube and Konveyor Setup

### Step 1.1: Configure and Start Minikube

Configure Minikube with adequate resources:

```bash
# Configure Minikube resources
minikube config set memory 10240
minikube config set cpus 4

# Start Minikube with required addons
minikube start --addons=dashboard --addons=ingress
```

### Step 1.2: Install Operator Lifecycle Manager (OLM)

Since Minikube's OLM addon is disabled, install it manually:

```bash
# Download and run OLM installation script
curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.28.0/install.sh -o install.sh
chmod +x install.sh
./install.sh v0.28.0
```

### Step 1.3: Install Konveyor Operator with Authentication

Use the setup script from the tackle2-ui repository:

```bash
# Download and run the Konveyor setup script
curl https://raw.githubusercontent.com/konveyor/tackle2-ui/main/hack/setup-operator.sh -o setup-operator.sh
chmod +x setup-operator.sh

# Enable authentication and install
export FEATURE_AUTH_REQUIRED=true
./setup-operator.sh
```

**Note**: The script will:
- Apply necessary Custom Resources (CRs)
- Set up the Tackle instance with authentication
- Configure Keycloak with the `tackle` realm

### Step 1.4: Verify Installation

Wait for all pods to be ready:

```bash
# Check Konveyor namespace
kubectl get pods -n konveyor-tackle

# All pods should be in Running state
```

## Phase 2: Local Development Environment

### Step 2.1: Clone tackle2-ui Repository

```bash
cd ~/Development
git clone https://github.com/konveyor/tackle2-ui.git
cd tackle2-ui
```

### Step 2.2: Install Dependencies

```bash
npm install
```

### Step 2.3: Start Local Development Server

Enable authentication and start the development server:

```bash
export AUTH_REQUIRED=true
npm run start:dev
```

This command will:
- Set up port forwarding:
  - Hub API: `localhost:9002` → Kubernetes service
  - Keycloak: `localhost:9001` → Kubernetes service
- Build common packages in watch mode
- Start the server on port `9000`
- Start the client webpack dev server on port `9003`

**Important**: Keep this terminal running throughout the development session.

## Phase 3: Ngrok Tunnel Setup

### Step 3.1: Configure Ngrok Authentication

If you haven't already, sign up at [ngrok.com](https://dashboard.ngrok.com/signup) and get your authtoken:

```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN_HERE
```

### Step 3.2: Start Ngrok Tunnel

Use the provided management script to start the tunnel:

```bash
./ngrok-tunnel.sh start
```

**Note**: The script starts without `--host-header` flag by default to maintain OAuth compatibility.

### Step 3.3: Retrieve the Public URL

The script will display the public URL. You can also retrieve it later:

```bash
# Get the URL
./ngrok-tunnel.sh url

# Check tunnel status
./ngrok-tunnel.sh status
```

The public URL (e.g., `https://abc123.ngrok-free.dev`) will be saved to `.ngrok_url` file.

## Phase 4: Keycloak Client Configuration

### Step 4.1: Create Backstage Provider Client

Run the Keycloak client creation script:

```bash
./tackle-create-keycloak-client-fixed.sh
```

This script will:
1. Authenticate as Keycloak admin using credentials from the `tackle-keycloak-sso` secret
2. Create a client named `backstage-provider` with:
   - Client Secret: `backstage-provider-secret`
   - Service Account enabled
   - Required roles: `tackle-admin` and `default-roles-tackle`
   - All available client scopes

### Step 4.2: Verify Client Creation

You can verify the client was created successfully by accessing Keycloak:

```bash
# Port-forward Keycloak if not already done
kubectl port-forward svc/tackle-keycloak-sso -n konveyor-tackle 9001:8080

# Access Keycloak at http://localhost:9001/auth
# Login with admin credentials from the secret
```

## Phase 5: RHDH Configuration and Launch

For this phase, we'll use the official [rhdh-local](https://github.com/redhat-developer/rhdh-local) repository, which provides the fastest and simplest way to test Red Hat Developer Hub features locally.

### Step 5.1: Clone rhdh-local Repository

```bash
# Clone the official rhdh-local repository
git clone https://github.com/redhat-developer/rhdh-local.git
cd rhdh-local
```

### Step 5.2: Configure MTA Plugin

Copy the example configuration files from this repository to rhdh-local:

```bash
# Copy the app-config.local.yaml (contains MTA plugin configuration)
cp /path/to/rhdh-test-e2e/local/app-config.local.yaml ./

# Copy the dynamic plugins configuration
cp /path/to/rhdh-test-e2e/local/dynamic-plugins.override.yaml ./
```

### Step 5.3: Update Configuration with Your Ngrok URL

Edit `app-config.local.yaml` and update the MTA configuration with your ngrok URL:

```yaml
# MTA Plugin Configuration
mta:
  url: https://YOUR-NGROK-URL.ngrok-free.dev  # Replace with your actual ngrok URL
  providerAuth:
    realm: tackle  # This is correct for local Minikube Keycloak setup
    secret: backstage-provider-secret
    clientID: backstage-provider
```

**Important**: The `realm: tackle` setting is correct for the local Minikube Keycloak instance we set up in Phase 1.

### Step 5.4: Start RHDH Local

Using Podman (recommended):

```bash
podman compose up -d
```

Or using Docker:

```bash
docker compose up -d
```

### Step 5.5: Access RHDH

1. Open your browser and navigate to: `http://localhost:7007`
2. Log in as 'Guest' (default for rhdh-local)
3. Navigate to a service entity in the catalog to see the MTA tab

### Step 5.6: Verify MTA Plugin Integration

1. Check that the MTA plugin loads correctly in the entity pages
2. Verify the connection to your local MTA instance through ngrok
3. Check logs if needed:
   ```bash
   # Podman
   podman compose logs rhdh --tail 20
   
   # Docker
   docker compose logs rhdh --tail 20
   ```

### Step 5.7: Restart After Configuration Changes

If you need to make configuration changes:

```bash
# Podman
podman compose stop rhdh && podman compose start rhdh

# Docker
docker compose stop rhdh && docker compose start rhdh
```

**Note**: The rhdh-local repository includes comprehensive TechDocs that you can access directly in the application for detailed guides on plugins, configurations, and troubleshooting.

## Verification Steps

### 1. Verify Minikube and Konveyor

```bash
# Check all pods are running
kubectl get pods -n konveyor-tackle

# Expected: All pods should be in Running state
```

### 2. Verify Local Development

- Access tackle2-ui: `http://localhost:9003`
- Login with Keycloak credentials
- Verify you can see the MTA dashboard

### 3. Verify Ngrok Tunnel

```bash
# Check tunnel status
./ngrok-tunnel.sh status

# Test the public URL
curl -I https://YOUR-NGROK-URL.ngrok-free.dev
```

### 4. Verify RHDH Integration

1. Navigate to a service entity in RHDH catalog
2. Check for the "MTA" tab
3. Verify the MTA plugin loads correctly

## Troubleshooting

### Common Issues and Solutions

#### 1. Minikube Won't Start

```bash
# Clean up and restart
minikube delete
minikube start --addons=dashboard --addons=ingress
```

#### 2. Konveyor Pods Not Starting

```bash
# Check operator logs
kubectl logs -n konveyor-tackle deployment/tackle-operator

# Check for PVC issues
kubectl get pvc -n konveyor-tackle
```

#### 3. Authentication Issues

```bash
# Verify Keycloak is running
kubectl get pod -n konveyor-tackle | grep keycloak

# Check Keycloak logs
kubectl logs -n konveyor-tackle -l app.kubernetes.io/name=keycloak
```

#### 4. Ngrok Connection Issues

```bash
# Restart ngrok tunnel
./ngrok-tunnel.sh restart

# Check ngrok dashboard
open http://localhost:4040
```

#### 5. RHDH Can't Connect to MTA

- Verify the ngrok URL in `app-config.local.yaml` is correct
- Check if the backstage-provider client exists in Keycloak
- Verify RHDH container can reach the ngrok URL
- Ensure you're using the correct realm (`tackle`) in the configuration
- Check rhdh-local logs: `podman compose logs rhdh -f`

#### 6. Dynamic Plugins Not Loading

- Verify `dynamic-plugins.override.yaml` was copied to rhdh-local directory
- Check plugin container images are accessible
- Review logs for plugin loading errors: `podman compose logs rhdh | grep -i plugin`

### Debug Commands

```bash
# Get all resources in konveyor-tackle namespace
kubectl get all -n konveyor-tackle

# Check service endpoints
kubectl get endpoints -n konveyor-tackle

# View operator logs
kubectl logs -n konveyor-tackle deployment/tackle-operator -f

# Check RHDH logs
docker compose logs rhdh -f
```

## Quick Reference

### Essential URLs

| Service | Local URL | Description |
|---------|-----------|-------------|
| tackle2-ui Dev | http://localhost:9003 | Development UI |
| Hub API | http://localhost:9000 | Local API server |
| Keycloak | http://localhost:9001/auth | Authentication service |
| Ngrok Dashboard | http://localhost:4040 | Tunnel management |
| RHDH | http://localhost:7007 | Red Hat Developer Hub |

### Key Scripts

| Script | Purpose |
|--------|---------|
| `setup-complete-environment.sh` | **Complete automated setup including rhdh-local** |
| `start-tackle2-ui-dev.sh` | Minikube + Konveyor setup |
| `setup-operator.sh` | Install Konveyor operator |
| `ngrok-tunnel.sh` | Manage ngrok tunnel |
| `tackle-create-keycloak-client-fixed.sh` | Create Backstage client |

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `FEATURE_AUTH_REQUIRED` | `true` | Enable Konveyor authentication |
| `AUTH_REQUIRED` | `true` | Enable tackle2-ui authentication |
| `NGROK_PORT` | `9000` | Port for ngrok tunnel |

### Default Directories

The automated setup script uses these default locations:
- tackle2-ui: `~/Development/tackle2-ui`
- rhdh-local: `~/Development/rhdh-local`

### Useful Aliases

Add these to your shell profile for convenience:

```bash
# Minikube kubectl
alias mkubectl="minikube kubectl --"

# Quick status checks
alias mta-status="kubectl get pods -n konveyor-tackle"
alias ngrok-url="./ngrok-tunnel.sh url"
alias rhdh-logs="cd ~/Development/rhdh-local && podman compose logs rhdh -f"
```

## Next Steps

After completing this setup, you can:

1. Develop and test MTA features locally
2. Create and test new RHDH templates for application migration
3. Debug MTA plugin issues in RHDH
4. Test authentication flows between RHDH and MTA
5. Contribute to the MTA or RHDH projects

## Additional Resources

- [Konveyor Documentation](https://konveyor.github.io/)
- [Red Hat Developer Hub Documentation](https://developers.redhat.com/rhdh)
- [Backstage Documentation](https://backstage.io/docs)
- [Ngrok Documentation](https://ngrok.com/docs)

---

**Note**: This walkthrough assumes you're working on macOS or Linux. Windows users may need to adjust certain commands or use WSL2.
