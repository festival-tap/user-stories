#!/bin/bash
# =============================================================================
# Black-Box Web UI Acceptance Runner
# Executes Playwright E2E suites against a running UI_URL over HTTP/HTTPS.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_URL="${UI_URL:-http://localhost:4200}"
BASE_URL="${BASE_URL:-http://localhost:8080/api/v1}"

export UI_URL BASE_URL

shopt -s nullglob
specs=("$SCRIPT_DIR"/*.spec.ts "$SCRIPT_DIR"/e2e/*.spec.ts)
if [ ${#specs[@]} -eq 0 ]; then
  echo "No Playwright .spec.ts suites found in acceptance-front/ yet — skipping."
  exit 0
fi

echo "Waiting for Web UI at ${UI_URL}..."
for _ in $(seq 1 30); do
  if curl -sSf "${UI_URL}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "Running Playwright black-box acceptance suites against ${UI_URL}..."
cd "$SCRIPT_DIR"
npx playwright test --project=chromium
