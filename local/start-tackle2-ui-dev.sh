#!/bin/bash

# Tackle2-UI Local Development Startup Script
# This script starts minikube and the tackle2-ui development environment
#1 setup tackle locally with minikube 
set -e

echo "🚀 Starting Tackle2-UI Local Development Environment..."

# Change to the tackle2-ui directory

echo "📦 Step 1: Starting minikube with dashboard and ingress addons..."
minikube config set memory 10240
minikube config set cpus 4
minikube start --addons=dashboard --addons=ingress

curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.28.0/install.sh -o install.sh
chmod +x install.sh
./install.sh v0.28.0

curl https://raw.githubusercontent.com/konveyor/tackle2-ui/main/hack/setup-operator.sh -o setup-operator.sh
chmod +x setup-operator.sh
export FEATURE_AUTH_REQUIRED=true
./setup-operator.sh

brew install coreutils

# Start the development environment
#2 run the dev server for tackle2-ui locally - served from 900

#export AUTH_REQUIRED=true
#npm run start:dev

##################
#3 create backstage client 
#./tackle-create-keycloak-client-fixed.sh
#4 setup ngrok ... 


#brew install ngrok

#ngrok http 9000

#use ./ngrok-tunnel.sh start 
#./ngrok-tunnel.sh status to see status of tunnel 



#curl -s http://localhost:4040/api/tunnels | jq '.tunnels[] | {name, public_url, config}'

#this will give url to put into app-config.local.yaml inside rhdh-local project. see example config in this repo. 

# will also need dynamic-plugins.override.yaml to copy over to rhdh-local for testing plugins








