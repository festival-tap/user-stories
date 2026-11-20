#!/bin/bash
# =============================================================================
# Acceptance Test: US-03 - Open a tap
# =============================================================================

set -euo pipefail

BASE_URL="http://localhost:8080/api/v1"
ADMIN_AUTH="-u admin:admax"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

echo "=== US-03: Open tap ==="

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

# 1. Open closed tap -> 204
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"open\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "204" ]; then
    fail "Open closed tap: expected 204, got $status"
fi
pass "Open closed tap returns 204"

# 2. Open already open tap -> 409
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"open\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "409" ]; then
    fail "Open already open tap: expected 409, got $status"
fi
pass "Open already open returns 409"

# 3. Open non-existent tap -> 404
fakeId="00000000-0000-0000-0000-000000000000"
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$fakeId/status" -H "Content-Type: application/json" -d "{\"status\": \"open\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "404" ]; then
    fail "Open non-existent tap: expected 404, got $status"
fi
pass "Open non-existent returns 404"

# 4. Invalid status value -> 400
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"half-open\", \"updated_at\": \"$timestamp\"}")
if [ "$status" != "400" ]; then
    fail "Invalid status: expected 400, got $status"
fi
pass "Invalid status returns 400"

echo "✅ US-03 PASSED"