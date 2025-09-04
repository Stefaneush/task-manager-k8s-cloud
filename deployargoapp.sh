#!/bin/bash

set -e

ENVIRONMENT=${1:-stg}
VALID_ENVS=("stg" "prod")

if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo "Error: Invalid environment. Use: stg or prod"
    exit 1
fi

echo "Deploying ArgoCD to environment: $ENVIRONMENT"

# Crear namespace argocd si no existe
kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar que los pods de ArgoCD estén listos
echo "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=ready pod --all -n argocd --timeout=180s

# Aplicar la app ArgoCD desde overlays según environment
if [ "$ENVIRONMENT" == "stg" ]; then
    kubectl apply -f overlays/stg/argo-app-stg.yaml -n argocd
else
    kubectl apply -f overlays/prod/argo-app-prod.yaml -n argocd
fi

# Mostrar contraseña inicial de ArgoCD
echo "ArgoCD initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo ""

# Port-forward para acceder a la UI de ArgoCD
echo "Starting port-forward to access ArgoCD UI at http://localhost:8080"
kubectl port-forward svc/argocd-server -n argocd 8080:443

