#!/bin/bash

# Deployment script for Task Manager K8s manifests with /etc/hosts update

set -e

ENVIRONMENT=${1:-stg}
VALID_ENVS=("stg" "prod")

if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo "Error: Invalid environment. Use: stg, or prod"
    exit 1
fi

PROFILE="task-manager-${ENVIRONMENT}"
HOST="task-manager.local"

echo "🚀 Deploying Task Manager to ${ENVIRONMENT} environment..."

# Create cluster
minikube start -p ${PROFILE} --memory=2048 --cpus=2

# Apply the kustomization
kubectl apply -k overlays/${ENVIRONMENT}

echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n task-manager

echo "✅ Deployment completed successfully!"

# Enable ingress addon
minikube addons enable ingress -p ${PROFILE}
echo "🌐 Ingress enabled"

# Update /etc/hosts with current Minikube IP
IP=$(minikube ip -p ${PROFILE})

if grep -q "$HOST" /etc/hosts; then
  sudo sed -i "s/^.*$HOST/$IP $HOST/" /etc/hosts
else
  echo "$IP $HOST" | sudo tee -a /etc/hosts
fi

echo "✔ /etc/hosts updated: $HOST -> $IP"

# Run ArgoCD deployment script
echo "📦 Running ArgoCD deployment script for environment ${ENVIRONMENT}..."
./deployargoapp.sh "$ENVIRONMENT"

