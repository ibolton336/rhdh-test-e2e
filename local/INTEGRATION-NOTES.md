# Integration Notes: RHDH-Local with MTA

## Overview

This setup integrates the official Red Hat Developer Hub Local (rhdh-local) repository with a local MTA/Konveyor instance running on Minikube. The integration allows testing of MTA plugins and features within RHDH without requiring a full cluster deployment.

## Key Integration Points

### 1. **rhdh-local Repository**
- Official repo: https://github.com/redhat-developer/rhdh-local
- Provides the simplest way to run RHDH locally
- Supports dynamic plugins via `dynamic-plugins.override.yaml`
- Uses Podman/Docker Compose for container orchestration

### 2. **Configuration Files**

#### app-config.local.yaml
- Contains MTA backend configuration only
- Key settings:
  - `mta.url`: Points to ngrok tunnel URL (exposing local MTA)
  - `mta.providerAuth.realm`: Set to `tackle` (matches Minikube Keycloak)
  - `mta.providerAuth.clientID`: `backstage-provider`
  - `mta.providerAuth.secret`: `backstage-provider-secret`
- Note: Dynamic plugin configurations should NOT be placed here

#### dynamic-plugins.override.yaml
- Defines all MTA dynamic plugins to load:
  - MTA Frontend Plugin (includes UI configuration)
  - MTA Backend Plugin (with embedded migrations)
  - MTA Scaffolder Action Plugin
  - MTA Entity Provider for catalog integration
- This is the ONLY place where dynamic plugin configurations should be defined

### 3. **Authentication Flow**

```
RHDH → Ngrok Tunnel → MTA Hub API → Keycloak (Minikube)
         ↓
    backstage-provider client
    (service account with tackle-admin role)
```

### 4. **Network Architecture**

- **MTA Services** (Minikube):
  - Hub API: Internal to Minikube
  - Keycloak: Port-forwarded to localhost:9001
  
- **Local Development**:
  - tackle2-ui dev server: localhost:9000
  - Exposed via ngrok: https://xxx.ngrok-free.dev
  
- **RHDH** (rhdh-local):
  - Runs on localhost:7007
  - Connects to MTA via ngrok URL

## Setup Dependencies

1. **Minikube** with Konveyor operator installed
2. **tackle2-ui** running locally with authentication enabled
3. **Keycloak client** (backstage-provider) created in tackle realm
4. **Ngrok tunnel** exposing local MTA instance
5. **rhdh-local** configured with MTA plugin settings

## Important Notes

### Realm Configuration
The `realm: tackle` setting in app-config.local.yaml must match the Keycloak realm created by the Konveyor operator setup. This is different from production setups where different realm names might be used.

### URL Updates
The ngrok URL changes each time the tunnel is restarted (unless using a paid ngrok account). Always update app-config.local.yaml with the current ngrok URL before starting rhdh-local.

### Plugin Versions
The dynamic-plugins.override.yaml references specific plugin versions. Update these as new versions become available:
- Frontend: `backstage-community-backstage-plugin-mta-frontend:next__0.4.0`
- Backend: Custom image with embedded migrations from quay.io/ibolton
- Scaffolder: `backstage-community-backstage-plugin-scaffolder-backend-module-mta:next__0.5.0`
- Entity Provider: `backstage-community-backstage-plugin-catalog-backend-module-mta-entity-provider:next__0.4.0`

### Development Workflow

1. Start Minikube and wait for all pods
2. Start tackle2-ui development server
3. Create Keycloak client
4. Start ngrok tunnel and note URL
5. Clone/update rhdh-local
6. Copy configuration files
7. Update ngrok URL in app-config.local.yaml
8. Start rhdh-local with podman/docker compose
9. Access RHDH at localhost:7007

### Troubleshooting

If MTA plugin doesn't load:
1. Verify ngrok tunnel is running: `./ngrok-tunnel.sh status`
2. Check Keycloak client exists: Access http://localhost:9001/auth
3. Verify RHDH can reach ngrok URL: Check rhdh container logs
4. Ensure all MTA pods are running: `kubectl get pods -n konveyor-tackle`

## References

- [RHDH Local Documentation](https://github.com/redhat-developer/rhdh-local)
- [Konveyor Documentation](https://konveyor.github.io/)
- [MTA Backstage Plugins](https://github.com/konveyor/backstage-plugins)
