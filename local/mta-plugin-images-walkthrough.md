# MTA Plugin Images - Build, Tag, and Push Walkthrough

This guide walks through creating container images for the MTA (Migration Toolkit for Applications) Backstage plugins and pushing them to Quay.io.

## 🚀 Quick Start (Recommended)

For a streamlined experience, use the automated script:

```bash
# Navigate to your local project directory
cd /Users/ibolton/Development/rhdh-test-e2e/local

# Run the simplified build and push script
./push-mta-plugin.sh
```

This script:
- Uses Docker exclusively for all operations
- Automatically detects plugin version from package.json
- Builds, tags, and pushes in one command
- Provides ready-to-use YAML configuration

## Prerequisites

- Access to the community-plugins repository with MTA plugins
- Docker installed and authenticated with Quay.io
- Red Hat Developer Hub CLI (`@red-hat-developer-hub/cli`)

## Plugin Locations

- **Backend Plugin**: `workspaces/mta/plugins/mta-backend/`
- **Frontend Plugin**: `workspaces/mta/plugins/mta-frontend/`

## Step 1: Build Plugin Images

### Backend Plugin

```bash
# Navigate to backend plugin directory
cd workspaces/mta/plugins/mta-backend/

# Build the image using RHDH CLI
npx @red-hat-developer-hub/cli@latest plugin package --tag quay.io/rhdh-community/backstage-plugin-mta-backend:v0.4.0-embedded-migrations
```

### Frontend Plugin

```bash
# Navigate to frontend plugin directory
cd workspaces/mta/plugins/mta-frontend/

# Build the image using RHDH CLI
npx @red-hat-developer-hub/cli@latest plugin package --tag quay.io/rhdh-community/backstage-plugin-mta-frontend:v0.4.0
```

## Step 2: Tag Images for Personal Namespace

If you don't have push access to the `rhdh-community` organization, tag the images to your personal namespace:

```bash
# Tag backend plugin
docker tag quay.io/rhdh-community/backstage-plugin-mta-backend:v0.4.0-embedded-migrations quay.io/ibolton/backstage-plugin-mta-backend:v0.4.0-embedded-migrations

# Tag frontend plugin
docker tag quay.io/rhdh-community/backstage-plugin-mta-frontend:v0.4.0 quay.io/ibolton/backstage-plugin-mta-frontend:v0.4.0
```

## Step 3: Verify Images

Check that both images are available in Docker:

```bash
docker images | grep "quay.io/ibolton.*mta"
```

Expected output:
```
quay.io/ibolton/backstage-plugin-mta-frontend   v0.4.0                       79dd2bee09d3   6 minutes ago   8.95MB
quay.io/ibolton/backstage-plugin-mta-backend    v0.4.0-embedded-migrations   9f10cc0198db   4 days ago      1.41MB
```

## Step 4: Push Images to Quay.io

```bash
# Push backend plugin
docker push quay.io/ibolton/backstage-plugin-mta-backend:v0.4.0-embedded-migrations

# Push frontend plugin
docker push quay.io/ibolton/backstage-plugin-mta-frontend:v0.4.0
```

## Step 5: Using the Images in Red Hat Developer Hub

Add the following to your `dynamic-plugins.yaml` configuration:

```yaml
plugins:
  # MTA Backend Plugin
  - package: oci://quay.io/ibolton/backstage-plugin-mta-backend:v0.4.0-embedded-migrations!backstage-community-backstage-plugin-mta-backend
    disabled: false

  # MTA Frontend Plugin
  - package: oci://quay.io/ibolton/backstage-plugin-mta-frontend:v0.4.0!backstage-community-backstage-plugin-mta-frontend
    disabled: false
```

## Troubleshooting

### Authentication Issues
If you get authentication errors when pushing:
```bash
# Login to Quay with Docker
docker login quay.io
```

### Version Mismatches
Make sure the version in your `package.json` matches the tag you're using:
- Backend: Check `workspaces/mta/plugins/mta-backend/package.json`
- Frontend: Check `workspaces/mta/plugins/mta-frontend/package.json`

## Image Details

### Backend Plugin
- **Package Name**: `@backstage-community/backstage-plugin-mta-backend`
- **Role**: `backend-plugin`
- **Plugin ID**: `mta-backend`
- **Features**: Embedded migrations included

### Frontend Plugin
- **Package Name**: `@backstage-community/backstage-plugin-mta-frontend`
- **Role**: `frontend-plugin`
- **Plugin ID**: `mta-frontend`
- **Features**: React-based UI components

## Notes

- The RHDH CLI automatically creates optimized container images with proper metadata
- Images use scratch base for minimal size
- Plugin metadata is embedded as OCI annotations
- Both plugins can be used independently or together for full MTA functionality

## Repository Structure

```
workspaces/mta/
├── plugins/
│   ├── mta-backend/           # Backend plugin source
│   ├── mta-frontend/          # Frontend plugin source
│   ├── catalog-backend-module-mta-entity-provider/
│   └── scaffolder-backend-module-mta/
├── package.json               # Workspace configuration
└── README.md
```