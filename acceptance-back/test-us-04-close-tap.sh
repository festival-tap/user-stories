#!/bin/bash
# =============================================================================
# Acceptance Test: US-04 - Close a tap
# =============================================================================

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080/api/v1}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-admax}"
ADMIN_AUTH="-u ${ADMIN_USER}:${ADMIN_PASS}"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

echo "=== US-04: Close tap ==="

# Helper to perform curl and extract status code and body
do_curl() {
    local method=$1
    local url=$2
    local data=$3
    local response_file=$(mktemp)
    local http_code=$(curl -s -w "%{http_code}" $ADMIN_AUTH -X "$method" "$url" -H "Content-Type: application/json" -d "$data" -o "$response_file")
    local body=$(cat "$response_file")
    rm -f "$response_file"
    echo "$http_code|$body"
}

# Create a dispenser
result=$(do_curl "POST" "$BASE_URL/dispenser" '{"flow_volume": 0.064}')
http_code=$(echo "$result" | cut -d'|' -f1)
body=$(echo "$result" | cut -d'|' -f2-)
if [ "$http_code" != "201" ]; then
    fail "Failed to create dispenser: HTTP $http_code, body: $body"
fi
tapId=$(echo "$body" | jq -r '.id')
if [ -z "$tapId" ] || [ "$tapId" = "null" ]; then
    fail "Failed to extract tapId from response: $body"
fi

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Open the tap first (so we can close it)
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"open\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "204" ]; then
    fail "Failed to open tap for test: $status"
fi

# 1. Close open tap -> 204
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"close\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "204" ]; then
    fail "Close open tap: expected 204, got $status"
fi
pass "Close open tap returns 204"

# 2. Close already closed tap -> 409
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"close\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "409" ]; then
    fail "Close already closed: expected 409, got $status"
fi
pass "Close already closed returns 409"

# 3. Close non-existent tap -> 404
fakeId="00000000-0000-0000-0000-000000000000"
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$fakeId/status" -H "Content-Type: application/json" -d "{\"status\": \"close\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "404" ]; then
    fail "Close non-existent: expected 404, got $status"
fi
pass "Close non-existent returns 404"

# 4. Invalid status -> 400
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"half-close\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "400" ]; then
    fail "Invalid status: expected 400, got $status"
fi
pass "Invalid status returns 400"

echo "✅ US-04 PASSED"