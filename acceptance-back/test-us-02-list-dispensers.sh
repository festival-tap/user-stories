#!/bin/bash
# =============================================================================
# Acceptance Test: US-02 - List all dispensers
# =============================================================================

set -euo pipefail

BASE_URL="http://localhost:8080/api/v1"
ADMIN_AUTH="-u admin:admax"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

echo "=== US-02: List dispensers ==="

# Ensure at least one dispenser exists
curl -s $ADMIN_AUTH -X POST "$BASE_URL/dispenser" -H "Content-Type: application/json" -d '{"flow_volume": 0.064}' > /dev/null

# List dispensers with authentication
resp=$(curl -s -w "%{http_code}" $ADMIN_AUTH "$BASE_URL/dispenser")
http_code=${resp: -3}
body=${resp%???}

if [ "$http_code" != "200" ]; then
    fail "Expected 200, got $http_code"
fi

# Verify response is a non‑empty JSON array
len=$(echo "$body" | jq length)
if [ "$len" -eq 0 ]; then
    fail "Expected non-empty array, got empty"
fi

# Verify each object has id and flow_volume
first_id=$(echo "$body" | jq -r '.[0].id')
first_flow=$(echo "$body" | jq -r '.[0].flow_volume')
if [ -z "$first_id" ] || [ "$first_id" = "null" ]; then
    fail "Missing id in first dispenser"
fi
if [ -z "$first_flow" ] || [ "$first_flow" = "null" ]; then
    fail "Missing flow_volume in first dispenser"
fi

pass "List returns non-empty array with correct fields"
echo "✅ US-02 PASSED"