# Red Hat Developer Hub (RHDH) + Migration Toolkit for Applications (MTA) Local Development Walkthrough

This comprehensive guide walks you through setting up a complete local development environment for Red Hat Developer Hub (RHDH) integrated with the Migration Toolkit for Applications (MTA/Konveyor) using Minikube.

> 📌 **Quick Links for Help**
> - Having issues? Jump to [Troubleshooting](#troubleshooting)
> - Need command reference? See [Quick Reference](#quick-reference)
> - Want automation? Use `./setup-complete-environment.sh`

## 🎯 What You'll Achieve

By the end of this walkthrough, you'll have:
- ✅ A local Kubernetes cluster (Minikube) running MTA/Konveyor
- ✅ Local development environment for tackle2-ui with hot-reload
- ✅ Public access to your local MTA via ngrok tunnel
- ✅ Red Hat Developer Hub running locally with MTA plugins
- ✅ Full authentication flow working between all components

**Total Setup Time**: Approximately 30-45 minutes

## 🗺️ Setup Flow Overview

Here's what we'll be doing:

```text
1. Install Prerequisites (10 min)
   ↓
2. Start Minikube & Install MTA/Konveyor (10 min)
   ↓
3. Start Local Development Server (5 min)
   ↓
4. Create Ngrok Tunnel (5 min)
   ↓
5. Configure Keycloak Authentication (5 min)
   ↓
6. Start RHDH with MTA Plugin (10 min)
   ↓
🎉 Ready to develop!
```

## 📋 Before You Begin

Make sure you have:
- [ ] At least 16GB RAM (10GB will be allocated to Minikube)
- [ ] At least 20GB free disk space
- [ ] Admin/sudo access on your machine
- [ ] Stable internet connection for downloading images

## Table of Contents

1. [Overview](#overview) - Understanding the architecture
2. [Prerequisites](#prerequisites) - Software requirements (~10 min)
3. [Phase 1: Minikube and Konveyor Setup](#phase-1-minikube-and-konveyor-setup) (~10 min)
4. [Phase 2: Local Development Environment](#phase-2-local-development-environment) (~5 min)
5. [Phase 3: Ngrok Tunnel Setup](#phase-3-ngrok-tunnel-setup) (~5 min)
6. [Phase 4: Keycloak Client Configuration](#phase-4-keycloak-client-configuration) (~5 min)
7. [Phase 5: RHDH Configuration and Launch](#phase-5-rhdh-configuration-and-launch) (~10 min)
8. [Verification Steps](#verification-steps) - Confirm everything works
9. [Troubleshooting](#troubleshooting) - Common issues and fixes
10. [Quick Reference](#quick-reference) - Handy commands and URLs

## 🚀 Automated Setup Option

**Want to skip the manual steps?** We have an automated script that does everything for you:

```bash
cd /path/to/rhdh-test-e2e/local
./setup-complete-environment.sh
```

This script will handle all the phases automatically. However, we recommend going through the manual steps at least once to understand how everything works.

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

### 🔧 Required Software

Install these tools before proceeding. Check each box as you complete:

- [ ] **Container Runtime** (choose one):
  - Docker Desktop: [Download](https://www.docker.com/products/docker-desktop/)
  - Podman: `brew install podman` (macOS) or [Installation Guide](https://podman.io/getting-started/installation)

- [ ] **Minikube**: [Installation Guide](https://minikube.sigs.k8s.io/docs/start/)
  ```bash
  # macOS
  brew install minikube
  
  # Linux
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  ```

- [ ] **kubectl**: Usually comes with Minikube, but can install separately:
  ```bash
  # macOS
  brew install kubectl
  
  # Linux
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install kubectl /usr/local/bin/kubectl
  ```

- [ ] **Node.js v18+**: [Download](https://nodejs.org/) or use nvm:
  ```bash
  # Using nvm (recommended)
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
  nvm install 18
  nvm use 18
  ```

- [ ] **Git**: [Download](https://git-scm.com/downloads)

- [ ] **ngrok**: Create a free account at [ngrok.com](https://dashboard.ngrok.com/signup)
  ```bash
  # macOS
  brew install ngrok
  
  # Linux
  curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
  sudo apt update && sudo apt install ngrok
  ```

- [ ] **Additional Tools**:
  ```bash
  # macOS
  brew install jq coreutils
  
  # Linux (Ubuntu/Debian)
  sudo apt-get install jq coreutils
  ```

### ✅ Verify Installation

Run this script to check all prerequisites:

```bash
echo "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || command -v podman >/dev/null 2>&1 && echo "✓ Container runtime" || echo "✗ Container runtime missing"
command -v minikube >/dev/null 2>&1 && echo "✓ Minikube" || echo "✗ Minikube missing"
command -v kubectl >/dev/null 2>&1 && echo "✓ kubectl" || echo "✗ kubectl missing"
command -v node >/dev/null 2>&1 && echo "✓ Node.js $(node -v)" || echo "✗ Node.js missing"
command -v git >/dev/null 2>&1 && echo "✓ Git" || echo "✗ Git missing"
command -v ngrok >/dev/null 2>&1 && echo "✓ ngrok" || echo "✗ ngrok missing"
command -v jq >/dev/null 2>&1 && echo "✓ jq" || echo "✗ jq missing"
```

## Phase 1: Minikube and Konveyor Setup

> 🎯 **Goal**: Set up a local Kubernetes cluster with MTA/Konveyor installed
> 
> ⏱️ **Estimated Time**: 10 minutes

### Step 1.1: Configure and Start Minikube

First, let's set up Minikube with enough resources:

```bash
# Configure Minikube resources
minikube config set memory 10240
minikube config set cpus 4

# Start Minikube with required addons
minikube start --addons=dashboard --addons=ingress
```

🔄 **Expected Output**: You should see messages about downloading images and starting the cluster. This may take 3-5 minutes.

✅ **Checkpoint**: Verify Minikube is running:
```bash
minikube status
# Should show:
# host: Running
# kubelet: Running
# apiserver: Running
```

### Step 1.2: Install Operator Lifecycle Manager (OLM)

OLM is required to install the Konveyor operator:

```bash
# Download and run OLM installation script
curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.28.0/install.sh -o install.sh
chmod +x install.sh
./install.sh v0.28.0
```

🔄 **Expected Output**: You'll see resources being created in the `olm` namespace.

✅ **Checkpoint**: Verify OLM is installed:
```bash
kubectl get pods -n olm
# Should show several running pods
```

### Step 1.3: Install Konveyor Operator with Authentication

Now we'll install MTA/Konveyor with authentication enabled:

```bash
# Download the Konveyor setup script
curl https://raw.githubusercontent.com/konveyor/tackle2-ui/main/hack/setup-operator.sh -o setup-operator.sh
chmod +x setup-operator.sh

# Enable authentication and install
export FEATURE_AUTH_REQUIRED=true
./setup-operator.sh
```

📝 **What this does**:
- Installs the Konveyor operator
- Creates a Tackle instance with authentication
- Sets up Keycloak for user management
- Creates the `tackle` realm for authentication

🔄 **Expected Output**: The script will show progress as it creates various resources.

### Step 1.4: Wait for Installation to Complete

The installation takes a few minutes. Let's monitor the progress:

```bash
# Watch pods being created (press Ctrl+C to exit)
watch kubectl get pods -n konveyor-tackle
```

✅ **Success Criteria**: All pods should show `Running` status (this may take 3-5 minutes):
- `tackle-hub-*` (2 pods)
- `tackle-keycloak-*` (1 pod)
- `tackle-postgres-*` (1 pod)
- `tackle-ui-*` (1 pod)

💡 **Tip**: If pods are stuck in `Pending` or `ContainerCreating`, wait a bit longer. First-time image pulls can be slow.

## Phase 2: Local Development Environment

> 🎯 **Goal**: Set up the tackle2-ui development environment with hot-reload
> 
> ⏱️ **Estimated Time**: 5 minutes

### Step 2.1: Clone tackle2-ui Repository

First, create a development directory and clone the repository:

```bash
# Create development directory if it doesn't exist
mkdir -p ~/Development
cd ~/Development

# Clone the repository
git clone https://github.com/konveyor/tackle2-ui.git
cd tackle2-ui
```

✅ **Checkpoint**: You should now be in the `~/Development/tackle2-ui` directory.

### Step 2.2: Install Dependencies

Install all required Node.js packages:

```bash
npm install
```

🔄 **Expected Output**: npm will download and install dependencies. This may take 2-3 minutes.

⚠️ **Common Issue**: If you see permission errors, make sure you're using Node.js v18+ (check with `node -v`).

### Step 2.3: Start Local Development Server

Now let's start the development server with authentication enabled:

```bash
# Enable authentication to match our Konveyor setup
export AUTH_REQUIRED=true

# Start the development server
npm run start:dev
```

📝 **What happens when you run this**:
1. **Port forwarding** is automatically set up:
   - `localhost:9001` → Keycloak (for authentication)
   - `localhost:9002` → Hub API (backend services)
2. **Development servers** start:
   - `localhost:9000` → Backend server
   - `localhost:9003` → Frontend with hot-reload

🔄 **Expected Output**: You'll see webpack compilation messages and server startup logs.

✅ **Success Indicator**: Look for these messages:

```text
✔ Webpack compiled successfully
Server listening on port 9000
```

⚠️ **IMPORTANT**: Keep this terminal open! The development server needs to stay running.

💡 **Pro Tip**: Open a new terminal tab/window for the remaining steps.

## Phase 3: Ngrok Tunnel Setup

> 🎯 **Goal**: Expose your local MTA instance to the internet so RHDH can access it
> 
> ⏱️ **Estimated Time**: 5 minutes

### Step 3.1: Configure Ngrok Authentication

First, you need a free ngrok account:

1. Sign up at [ngrok.com](https://dashboard.ngrok.com/signup) (free account is sufficient)
2. Copy your authtoken from the [dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)
3. Configure ngrok with your token:

```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN_HERE
```

✅ **Checkpoint**: Verify ngrok is configured:
```bash
ngrok config check
# Should show: Valid configuration file
```

### Step 3.2: Navigate to the Scripts Directory

Make sure you're in the directory with our helper scripts:

```bash
cd /path/to/rhdh-test-e2e/local
```

### Step 3.3: Start Ngrok Tunnel

Use the provided script to start the tunnel:

```bash
./ngrok-tunnel.sh start
```

🔄 **Expected Output**:

```text
[INFO] Starting ngrok tunnel on port 9000...
[SUCCESS] Tunnel started successfully!

🌐 Public URL: https://abc123.ngrok-free.dev
📊 Dashboard: http://localhost:4040
🔧 Local: http://localhost:9000
```

📝 **Important**: Copy the public URL (e.g., `https://abc123.ngrok-free.dev`) - you'll need it for Phase 5!

### Step 3.4: Verify the Tunnel

Let's make sure the tunnel is working:

```bash
# Check tunnel status
./ngrok-tunnel.sh status

# Test the public URL (replace with your actual URL)
curl -I https://YOUR-URL.ngrok-free.dev
```

✅ **Success Indicator**: The curl command should return `HTTP/2 200` or similar.

💡 **Tips**:
- The URL is saved to `.ngrok_url` file for easy reference
- Visit http://localhost:4040 to see the ngrok dashboard
- Free ngrok URLs change each time you restart the tunnel

## Phase 4: Keycloak Client Configuration

> 🎯 **Goal**: Create a service account for RHDH to authenticate with MTA
> 
> ⏱️ **Estimated Time**: 5 minutes

### Step 4.1: Create Backstage Provider Client

Stay in the scripts directory and run the Keycloak client creation script:

```bash
# Make sure you're in the right directory
cd /path/to/rhdh-test-e2e/local

# Run the script
./tackle-create-keycloak-client-fixed.sh
```

📝 **What this script does**:
1. Fetches admin password from Kubernetes secrets
2. Authenticates with Keycloak
3. Creates a service account called `backstage-provider`
4. Assigns necessary permissions for RHDH to access MTA

🔄 **Expected Output**:

```text
Using Keycloak URL: http://localhost:9001/auth
Decoded Password: [password shown]
Access Token: [token shown]
Creating client 'backstage-provider'...
Client UUID: [uuid shown]
Keycloak client 'backstage-provider' has been created successfully
```

### Step 4.2: Verify Client Creation (Optional)

If you want to see the client in Keycloak's UI:

```bash
# Open Keycloak admin console
open http://localhost:9001/auth
```

📝 **Login credentials**:
- Username: `admin`
- Password: (shown in the script output)

Navigate to: **Tackle realm** → **Clients** → **backstage-provider**

✅ **Success Criteria**: The `backstage-provider` client should be listed with:
- Service Account Enabled: ✓
- Client Secret: `backstage-provider-secret`

## Phase 5: RHDH Configuration and Launch

> 🎯 **Goal**: Set up Red Hat Developer Hub with the MTA plugin connected to your local instance
> 
> ⏱️ **Estimated Time**: 10 minutes

### Step 5.1: Clone rhdh-local Repository

Let's get the official RHDH local development environment:

```bash
# Navigate to your development directory
cd ~/Development

# Clone the official rhdh-local repository
git clone https://github.com/redhat-developer/rhdh-local.git
cd rhdh-local
```

✅ **Checkpoint**: You should now be in the `~/Development/rhdh-local` directory.

### Step 5.2: Copy Configuration Files

Copy the MTA configuration files from our scripts directory:

```bash
# Copy the configuration files (adjust the path as needed)
cp /path/to/rhdh-test-e2e/local/app-config.local.yaml ./
cp /path/to/rhdh-test-e2e/local/dynamic-plugins.override.yaml ./
```

📝 **What these files do**:
- `app-config.local.yaml`: Tells RHDH where to find your MTA instance
- `dynamic-plugins.override.yaml`: Loads the MTA plugins into RHDH

### Step 5.3: Update Configuration with Your Ngrok URL

Now we need to tell RHDH where to find your MTA instance:

```bash
# Open the config file in your editor
# For example: nano app-config.local.yaml
```

Find this section and replace `YOUR-NGROK-URL` with your actual ngrok URL from Phase 3:

```yaml
mta:
  url: https://abc123.ngrok-free.dev  # ← Replace with YOUR ngrok URL
  providerAuth:
    realm: tackle
    secret: backstage-provider-secret
    clientID: backstage-provider
```

💡 **Tip**: You can get your ngrok URL again by running:
```bash
cd /path/to/rhdh-test-e2e/local && ./ngrok-tunnel.sh url
```

### Step 5.4: Start RHDH

Now let's start Red Hat Developer Hub:

```bash
# If you have Podman (recommended)
podman compose up -d

# OR if you have Docker
docker compose up -d
```

🔄 **Expected Output**: You'll see images being pulled and containers starting.

⏳ **Wait Time**: First startup may take 2-3 minutes as it downloads images.

### Step 5.5: Access RHDH

Once started, open your browser and go to:

🌐 **http://localhost:7007**

📝 **Login**: Click "Sign In" and select "Guest" (no password needed for local development)

### Step 5.6: Verify MTA Plugin is Working

Let's make sure everything is connected:

1. **Navigate to the Software Catalog**
   - Click on "Catalog" in the sidebar
   - Click on any component (or create one if none exist)

2. **Look for the MTA Tab**
   - You should see an "MTA" tab on the entity page
   - Click it to verify it loads correctly

3. **Check the Connection**
   - The MTA tab should load without errors
   - If you see authentication errors, double-check your ngrok URL

✅ **Success Indicators**:
- RHDH loads at http://localhost:7007
- You can sign in as Guest
- MTA tab appears on entity pages
- No error messages in the MTA tab

### Step 5.7: Troubleshooting Tips

If something isn't working:

```bash
# Check RHDH logs
podman compose logs rhdh -f  # or docker compose logs rhdh -f

# Common fixes:
# 1. Wrong ngrok URL? Update app-config.local.yaml and restart:
podman compose restart rhdh

# 2. Can't connect? Verify all services are running:
cd /path/to/rhdh-test-e2e/local
./ngrok-tunnel.sh status
kubectl get pods -n konveyor-tackle
```

🎉 **Congratulations!** You now have a complete local development environment with RHDH and MTA!

## Verification Steps

> 🔍 **Let's make sure everything is working correctly**

### ✅ Quick Health Check

Run this script to verify all services:

```bash
echo "=== Service Status Check ==="
echo ""
echo "1. Minikube:"
minikube status | grep -E "host|kubelet|apiserver" || echo "❌ Minikube not running"
echo ""
echo "2. Konveyor Pods:"
kubectl get pods -n konveyor-tackle --no-headers | grep -v "Running" && echo "❌ Some pods not ready" || echo "✅ All pods running"
echo ""
echo "3. Ngrok Tunnel:"
curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1 && echo "✅ Ngrok running" || echo "❌ Ngrok not running"
echo ""
echo "4. Local Services:"
curl -s http://localhost:9000 > /dev/null 2>&1 && echo "✅ MTA API running" || echo "❌ MTA API not accessible"
curl -s http://localhost:9003 > /dev/null 2>&1 && echo "✅ tackle2-ui running" || echo "❌ tackle2-ui not accessible"
curl -s http://localhost:7007 > /dev/null 2>&1 && echo "✅ RHDH running" || echo "❌ RHDH not accessible"
```

### 🌐 Manual Verification

1. **Test MTA UI directly**: 
   - Open http://localhost:9003
   - You should see the MTA login page
   - Login with default credentials (if prompted)

2. **Test RHDH Integration**:
   - Open http://localhost:7007
   - Sign in as Guest
   - Go to Catalog → Select any component
   - Click the "MTA" tab
   - Should load without errors

3. **Test Ngrok Connection**:
   - Visit your ngrok URL in a browser
   - Should redirect to MTA login page

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

## 🎓 Summary

You've successfully set up a complete local development environment! Here's what you've accomplished:

### ✅ What's Now Running

| Service | URL | Purpose |
|---------|-----|---------|
| **RHDH** | http://localhost:7007 | Red Hat Developer Hub with MTA plugin |
| **tackle2-ui** | http://localhost:9003 | MTA UI (development mode) |
| **MTA API** | http://localhost:9000 | Backend API server |
| **Keycloak** | http://localhost:9001/auth | Authentication service |
| **Ngrok** | https://YOUR-URL.ngrok-free.dev | Public tunnel to MTA |

### 🔄 Common Daily Tasks

**Start everything after a reboot:**
```bash
# 1. Start Minikube
minikube start

# 2. Start tackle2-ui dev server
cd ~/Development/tackle2-ui
export AUTH_REQUIRED=true
npm run start:dev

# 3. Start ngrok tunnel
cd /path/to/rhdh-test-e2e/local
./ngrok-tunnel.sh start

# 4. Start RHDH
cd ~/Development/rhdh-local
podman compose up -d
```

**Stop everything:**
```bash
# Stop RHDH
cd ~/Development/rhdh-local && podman compose down

# Stop ngrok
cd /path/to/rhdh-test-e2e/local && ./ngrok-tunnel.sh stop

# Stop tackle2-ui (Ctrl+C in that terminal)

# Stop Minikube
minikube stop
```

### 🚀 What's Next?

Now that everything is running, you can:

1. **Explore RHDH Features**
   - Create software catalog entries
   - Test MTA analysis on applications
   - Create templates for migration projects

2. **Develop MTA Features**
   - Make changes to tackle2-ui code
   - See changes instantly with hot-reload
   - Test integration with RHDH

3. **Learn More**
   - Check out the [MTA Documentation](https://konveyor.github.io/)
   - Explore [RHDH Documentation](https://developers.redhat.com/rhdh)
   - Join the community discussions

### 💬 Need Help?

- **Issues with this setup?** Check the [Troubleshooting](#troubleshooting) section
- **MTA questions?** Visit [Konveyor GitHub](https://github.com/konveyor)
- **RHDH questions?** Visit [RHDH GitHub](https://github.com/redhat-developer/rhdh-local)

---

**Note**: This walkthrough assumes you're working on macOS or Linux. Windows users may need to adjust certain commands or use WSL2.
