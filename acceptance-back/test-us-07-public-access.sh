#!/bin/bash
# =============================================================================
# Acceptance Test: US-07 - Public access to tap list and status change
# =============================================================================

set -euo pipefail

BASE_URL="http://localhost:8080/api/v1"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

echo "=== US-07: Public access (no authentication) ==="

# 1. GET /dispenser without auth should return 200 (or 404 if empty, but not 401)
status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/dispenser")
if [ "$status" = "401" ]; then
    fail "GET /dispenser should be public, got 401"
fi
if [ "$status" != "200" ] && [ "$status" != "404" ]; then
    fail "GET /dispenser returned unexpected status $status"
fi
pass "GET /dispenser accessible without auth"

# 2. Create a tap (requires auth) to test PUT /status
ADMIN_AUTH="-u admin:admax"
resp=$(curl -s -w "%{http_code}" $ADMIN_AUTH -X POST "$BASE_URL/dispenser" -H "Content-Type: application/json" -d '{"flow_volume": 0.064}')
http_code=${resp: -3}
body=${resp%???}
if [ "$http_code" != "201" ]; then
    fail "Failed to create tap for test: $http_code"
fi
tapId=$(echo "$body" | jq -r '.id')

# 3. PUT /status without auth should return 204 (or 409/400 but not 401)
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"open\", \"updated_at\": \"$timestamp\"}")
if [ "$status" = "401" ]; then
    fail "PUT /status should be public, got 401"
fi
if [ "$status" != "204" ] && [ "$status" != "409" ] && [ "$status" != "400" ]; then
    fail "PUT /status returned unexpected status $status"
fi
pass "PUT /status accessible without auth"

echo "✅ US-07 PASSED"