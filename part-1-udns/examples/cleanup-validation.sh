#!/usr/bin/env bash
set -euo pipefail

echo "Deleting all validation resources..."
oc delete -f part-1-udns/examples/all-validation-resources.yaml --ignore-not-found=true

echo "Deleting network bootstrap resources (if applied separately)..."
oc delete -f part-1-udns/examples/all-network-bootstrap.yaml --ignore-not-found=true

echo "Cleanup completed."
