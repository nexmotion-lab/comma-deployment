#!/bin/bash

set -euo pipefail

NAMESPACE="observability-stack"

echo "\n🔭  Observability stack deployment started.\n"

if ! kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
  kubectl apply -f resources/namespace.yml
  echo "\n🌐 Namespace '$NAMESPACE' created."
else
  echo "\n🌐 Namespace '$NAMESPACE' already exists."
fi

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

release_exists() {
  helm status "$1" --namespace="$NAMESPACE" > /dev/null 2>&1
}

echo "\n📦 Installing or upgrading Tempo..."

if release_exists tempo; then
  echo "⏫ Upgrading existing Tempo release..."
else
  echo "📦 Installing new Tempo release..."
fi

helm upgrade --install tempo --namespace="$NAMESPACE" grafana/tempo \
  --values helm/tempo-values.yml --version 1.9.0

echo "\n⌛ Waiting for Tempo to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=tempo \
  --timeout=90s \
  --namespace="$NAMESPACE"

echo "\n📦 Installing or upgrading Loki Stack (Grafana, Loki, Prometheus, Promtail)..."

if release_exists loki-stack; then
  echo "⏫ Upgrading existing Loki Stack release..."
else
  echo "📦 Installing new Loki Stack release..."
fi

kubectl apply -f resources/dashboards

helm upgrade --install loki-stack --namespace="$NAMESPACE" grafana/loki-stack \
  --values helm/loki-stack-values.yml --version 2.10.2

echo "\n⌛ Waiting for Promtail to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=promtail \
  --timeout=90s \
  --namespace="$NAMESPACE"

echo "\n⌛ Waiting for Prometheus to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app=prometheus \
  --timeout=90s \
  --namespace="$NAMESPACE"

echo "\n⌛ Waiting for Loki to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app=loki \
  --timeout=90s \
  --namespace="$NAMESPACE"

echo "\n⌛ Waiting for Grafana to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=grafana \
  --timeout=90s \
  --namespace="$NAMESPACE"

echo "\n✅  Grafana observability stack has been successfully deployed."

echo "\n🔐 Your Grafana admin credentials...\n"

echo "Admin Username: user"
echo "Admin Password: $(kubectl get secret --namespace $NAMESPACE loki-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"

echo "\n🔭  Observability stack deployment completed.\n"
