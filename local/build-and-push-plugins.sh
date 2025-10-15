#!/bin/bash

# Script to build and push MTA plugins to quay.io
# Usage: ./build-and-push-plugins.sh [backend|frontend|both]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKEND_DIR="$SCRIPT_DIR/plugins/mta-backend"
FRONTEND_DIR="$SCRIPT_DIR/plugins/mta-frontend"

# Default to building both
BUILD_TARGET="${1:-both}"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  MTA Plugin Build & Push Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Function to build a plugin
build_plugin() {
    local plugin_name=$1
    local plugin_dir=$2
    
    echo -e "${YELLOW}→ Building $plugin_name plugin...${NC}"
    cd "$plugin_dir"
    
    # Clean
    echo "  Cleaning..."
    yarn clean > /dev/null 2>&1
    
    # Remove old dist-dynamic
    if [ -d "dist-dynamic" ]; then
        echo "  Removing old dist-dynamic..."
        rm -rf dist-dynamic
    fi
    
    # Build
    echo "  Running yarn build..."
    yarn build > /dev/null 2>&1
    
    echo -e "${GREEN}  ✓ Build complete${NC}"
}

# Function to package and push a plugin
package_and_push() {
    local plugin_name=$1
    local plugin_dir=$2
    local image_tag=$3
    
    echo -e "${YELLOW}→ Packaging $plugin_name plugin...${NC}"
    cd "$plugin_dir"
    
    # Package
    echo "  Creating container image..."
    npx --yes @red-hat-developer-hub/cli@latest plugin package --tag "$image_tag" > /dev/null 2>&1
    
    echo -e "${GREEN}  ✓ Image created${NC}"
    
    # Push
    echo -e "${YELLOW}→ Pushing $plugin_name to quay.io...${NC}"
    podman push "$image_tag:latest" > /dev/null 2>&1
    
    echo -e "${GREEN}  ✓ Pushed successfully${NC}"
    echo ""
}

# Build backend
if [ "$BUILD_TARGET" == "backend" ] || [ "$BUILD_TARGET" == "both" ]; then
    echo -e "${BLUE}[Backend Plugin]${NC}"
    build_plugin "backend" "$BACKEND_DIR"
    package_and_push "backend" "$BACKEND_DIR" "quay.io/ibolton/backstage-plugin-mta-backend"
fi

# Build frontend
if [ "$BUILD_TARGET" == "frontend" ] || [ "$BUILD_TARGET" == "both" ]; then
    echo -e "${BLUE}[Frontend Plugin]${NC}"
    build_plugin "frontend" "$FRONTEND_DIR"
    package_and_push "frontend" "$FRONTEND_DIR" "quay.io/ibolton/backstage-plugin-mta-frontend"
fi

# Show final image info
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ All operations completed successfully!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Images:"
podman images | grep "quay.io/ibolton/backstage-plugin-mta" | grep "latest"
echo ""
echo -e "${YELLOW}To deploy, update your dynamic-plugins.yaml with:${NC}"
echo ""
echo "plugins:"
if [ "$BUILD_TARGET" == "backend" ] || [ "$BUILD_TARGET" == "both" ]; then
    echo "  - package: oci://quay.io/ibolton/backstage-plugin-mta-backend!backstage-community-backstage-plugin-mta-backend"
    echo "    disabled: false"
fi
if [ "$BUILD_TARGET" == "frontend" ] || [ "$BUILD_TARGET" == "both" ]; then
    echo "  - package: oci://quay.io/ibolton/backstage-plugin-mta-frontend!backstage-community-backstage-plugin-mta-frontend"
    echo "    disabled: false"
fi
echo ""

