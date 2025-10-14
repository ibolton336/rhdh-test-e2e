# RHDH + MTA Local Development Environment

This directory contains all the scripts and documentation needed to set up a complete local development environment for Red Hat Developer Hub (RHDH) integrated with the Migration Toolkit for Applications (MTA/Konveyor).

This setup uses the official [rhdh-local](https://github.com/redhat-developer/rhdh-local) repository for running RHDH, which provides the fastest and simplest way to test Red Hat Developer Hub features locally.

## 📚 Documentation

- **[Full Walkthrough](RHDH-MTA-Local-Development-Walkthrough.md)** - Comprehensive guide with detailed explanations
- **[Quick Start Guide](RHDH-MTA-Quick-Start.md)** - Condensed version for experienced users
- **[Configuration Separation](CONFIG-SEPARATION.md)** - Clarifies where different configs should go
- **[Integration Notes](INTEGRATION-NOTES.md)** - Technical details about the integration

## 🚀 Automated Setup

For the fastest setup, use the complete environment script:

```bash
./setup-complete-environment.sh
```

This script automates:
- Minikube configuration and startup
- Konveyor operator installation
- tackle2-ui development setup
- Keycloak client creation
- Ngrok tunnel configuration
- rhdh-local setup with MTA plugin configuration

## 📁 Files Overview

### Setup Scripts

| Script | Purpose |
|--------|---------|
| `setup-complete-environment.sh` | **NEW** - Automated complete setup |
| `start-tackle2-ui-dev.sh` | Minikube + Konveyor setup |
| `setup-operator.sh` | Konveyor operator installation |
| `tackle-create-keycloak-client-fixed.sh` | Keycloak client for RHDH |
| `ngrok-tunnel.sh` | Ngrok tunnel management |

### Configuration Files

| File | Purpose |
|------|---------|
| `app-config.local.yaml` | RHDH configuration template |
| `dynamic-plugins.override.yaml` | MTA plugin configuration |

### Other Files

| File | Purpose |
|------|---------|
| `install.sh` | OLM installation script |
| `local-minikube-setup.md` | Original setup notes |

## 🔧 Manual Setup Steps

If you prefer manual setup or need to run individual components:

1. **Minikube & Konveyor**: `./start-tackle2-ui-dev.sh`
2. **tackle2-ui dev**: 
   ```bash
   cd ~/Development/tackle2-ui
   export AUTH_REQUIRED=true
   npm run start:dev
   ```
3. **Keycloak client**: `./tackle-create-keycloak-client-fixed.sh`
4. **Ngrok tunnel**: `./ngrok-tunnel.sh start`
5. **RHDH**: Update config and run `docker compose up -d`

## 🌐 Service URLs

Once everything is running:

- **tackle2-ui**: http://localhost:9003
- **Hub API**: http://localhost:9000
- **Keycloak**: http://localhost:9001/auth
- **Ngrok Dashboard**: http://localhost:4040
- **RHDH**: http://localhost:7007

## 🛠️ Utility Commands

### Check Status

```bash
# Konveyor pods
kubectl get pods -n konveyor-tackle

# Ngrok tunnel
./ngrok-tunnel.sh status

# RHDH logs
docker compose logs rhdh --tail 20
```

### Restart Services

```bash
# Ngrok tunnel
./ngrok-tunnel.sh restart

# RHDH
docker compose restart rhdh

# Konveyor pods
kubectl rollout restart deployment -n konveyor-tackle
```

### Cleanup

```bash
# Stop everything
minikube stop
./ngrok-tunnel.sh stop
docker compose down

# Full cleanup
minikube delete
```

## 🚨 Troubleshooting

See the [troubleshooting section](RHDH-MTA-Local-Development-Walkthrough.md#troubleshooting) in the full walkthrough for common issues and solutions.

## 🤝 Contributing

When making changes to these scripts:

1. Test the complete flow from scratch
2. Update relevant documentation
3. Ensure scripts are executable (`chmod +x`)
4. Add error handling for common failure cases

## 📝 Notes

- The setup requires ~10GB RAM and 4 CPU cores for Minikube
- Authentication is enabled by default for security
- Ngrok free tier is sufficient for development
- Scripts are designed for macOS/Linux (Windows users should use WSL2)
