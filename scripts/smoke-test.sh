#!/usr/bin/env bash

set -euo pipefail

check_url() {
  local label="$1"
  local url="$2"

  printf "Checking %-18s %s\n" "${label}" "${url}"
  curl --fail --silent --show-error --max-time 10 "${url}" >/dev/null
}

check_k8s() {
  echo "Checking Kubernetes namespace and service"
  kubectl get namespace production-apps >/dev/null
  kubectl get service nginx-service -n production-apps >/dev/null
}

echo "Running local platform smoke tests"

check_url "LocalStack" "http://127.0.0.1:4566/_localstack/health"
check_url "Web Server" "http://127.0.0.1:8080"
check_url "Prometheus" "http://127.0.0.1:9090/-/healthy"
check_url "Grafana" "http://127.0.0.1:3030/api/health"
check_url "Loki" "http://127.0.0.1:3100/ready"
check_url "Node Exporter" "http://127.0.0.1:9100/metrics"
check_k8s

echo "Smoke tests passed"
