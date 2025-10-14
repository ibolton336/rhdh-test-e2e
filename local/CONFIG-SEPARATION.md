# Configuration Separation Guide

This guide clarifies where different configurations should be placed when setting up RHDH with MTA plugins.

## app-config.local.yaml

This file should contain **backend service configurations only**:

```yaml
# MTA Backend Service Configuration
mta:
  url: https://YOUR-NGROK-URL.ngrok-free.dev  # MTA API endpoint
  providerAuth:
    realm: tackle                              # Keycloak realm
    secret: backstage-provider-secret          # Service account secret
    clientID: backstage-provider               # Service account client ID

# Other backend configurations
backend:
  baseUrl: http://localhost:7007

# Catalog configurations
catalog:
  # ... catalog settings ...
```

**DO NOT** put dynamic plugin configurations in this file.

## dynamic-plugins.override.yaml

This file should contain **all dynamic plugin configurations**:

```yaml
includes:
  - dynamic-plugins.default.yaml

plugins:
  # Frontend plugin with UI configuration
  - package: oci://path/to/mta-frontend-plugin
    disabled: false
    pluginConfig:
      dynamicPlugins:
        frontend:
          "backstage-community.backstage-plugin-mta-frontend":
            entityTabs:              # UI configuration
              - path: /mta
                title: MTA
                mountPoint: entity.page.mta
            mountPoints:
              - mountPoint: entity.page.mta/cards
                # ... mount point config ...

  # Backend plugins
  - package: oci://path/to/mta-backend-plugin
    disabled: false

  # Other plugins...
```

## Why This Separation?

1. **rhdh-local Design**: The rhdh-local project is designed to load dynamic plugins from `dynamic-plugins.override.yaml`
2. **Clear Separation**: Backend service configs vs. plugin loading configs
3. **Avoid Conflicts**: Prevents configuration conflicts and confusion
4. **Standard Practice**: Follows RHDH best practices for local development

## Common Mistake

❌ **Wrong**: Putting dynamic plugin config in app-config.local.yaml
```yaml
# app-config.local.yaml
dynamicPlugins:  # This should NOT be here!
  frontend:
    "backstage-community.backstage-plugin-mta-frontend":
      # ...
```

✅ **Correct**: All dynamic plugin configs in dynamic-plugins.override.yaml
```yaml
# dynamic-plugins.override.yaml
plugins:
  - package: oci://...
    pluginConfig:
      dynamicPlugins:
        frontend:
          # ...
```
