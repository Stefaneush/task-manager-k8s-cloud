#!/bin/bash

# Deployment script for Task Manager K8s manifests

set -e

ENVIRONMENT=${1:-stg}
VALID_ENVS=("stg" "prod")

if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo "Error: Invalid environment. Use: stg, or prod"
    exit 1
fi

echo "Deploying Task Manager to ${ENVIRONMENT} environment..."

# Create cluster
minikube start -p task-manager-${ENVIRONMENT} --memory=2048 --cpus=2

# Apply the kustomization
kubectl apply -k overlays/${ENVIRONMENT}

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n task-manager

echo "Deployment completed successfully!"

minikube addons enable ingress -p task-manager-${ENVIRONMENT}

echo "Ingress Enable"

# 🔁 Ejecutar el script de despliegue ArgoCD pasando el environment
echo "Running ArgoCD deployment script for environment ${ENVIRONMENT}..."
./deployargoapp.sh "$ENVIRONMENT"


