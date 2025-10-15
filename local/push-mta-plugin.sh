#!/bin/bash

# Simplified MTA Plugin Build and Push Script
# Uses Docker only - no bouncing between container runtimes!

set -e  # Exit on any error

# Configuration
PLUGIN_DIR="/Users/ibolton/Development/community-plugins/workspaces/mta/plugins/mta-frontend"
PLUGIN_VERSION="0.4.0"
QUAY_NAMESPACE="ibolton"  # Change this to your Quay.io namespace
IMAGE_NAME="backstage-plugin-mta-frontend"
FULL_TAG="quay.io/${QUAY_NAMESPACE}/${IMAGE_NAME}:v${PLUGIN_VERSION}"

echo "🚀 Building and pushing MTA Frontend Plugin to Quay.io"
echo "Plugin: ${IMAGE_NAME}"
echo "Version: ${PLUGIN_VERSION}"
echo "Target: ${FULL_TAG}"
echo

# Step 1: Navigate to plugin directory
echo "📁 Navigating to plugin directory..."
cd "${PLUGIN_DIR}"
pwd

# Step 2: Build the plugin image using RHDH CLI with Docker
echo "🔨 Building plugin image with RHDH CLI..."
export CONTAINER_TOOL=docker  # Force RHDH CLI to use Docker
npx @red-hat-developer-hub/cli@latest plugin package --tag "${FULL_TAG}"

# Step 3: Verify the image was created
echo "✅ Verifying image was created..."
docker images | grep "${QUAY_NAMESPACE}.*mta" || {
    echo "❌ Error: Image not found in Docker"
    exit 1
}

# Step 4: Test Docker login to Quay (will prompt if not logged in)
echo "🔐 Checking Quay.io authentication..."
docker login quay.io || {
    echo "❌ Error: Failed to authenticate with Quay.io"
    exit 1
}

# Step 5: Push the image
echo "📤 Pushing image to Quay.io..."
docker push "${FULL_TAG}"

echo
echo "🎉 Successfully pushed ${FULL_TAG}"
echo
echo "📋 To use in your dynamic-plugins.yaml:"
echo "  - package: oci://${FULL_TAG}!backstage-community-backstage-plugin-mta-frontend"
echo "    disabled: false"
echo