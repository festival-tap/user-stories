#!/bin/bash
# =============================================================================
# Frontend E2E Test Runner (no backend required)
# Run from: user-stories/acceptance-front/run-frontend-tests.sh
# =============================================================================

set -euo pipefail

# Get the project root (two levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT/frontend/beer-tap-ui"

echo "📦 Building Angular app..."
npm run build -- --configuration production

echo "🌐 Starting static server on port 4200..."
npx serve -s dist/beer-tap-ui/browser -l 4200 &
SERVER_PID=$!

# Wait for server to be ready
echo "⏳ Waiting for server..."
for i in {1..30}; do
  if curl -s http://localhost:4200 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "🧪 Running Playwright tests..."
npx playwright test e2e/bar-page.spec.ts --project=chromium

echo "🛑 Stopping server..."
kill $SERVER_PID 2>/dev/null || true

echo "✅ Frontend tests finished."