#!/bin/bash
# =============================================================================
# Acceptance Test: US-06 & US-07 - Authentication
# =============================================================================

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080/api/v1}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-admax}"
ADMIN_AUTH="-u ${ADMIN_USER}:${ADMIN_PASS}"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

echo "=== US-06 & US-07: Authentication ==="

# Helper to perform curl and extract status code and body
do_curl() {
    local auth=$1
    local method=$2
    local url=$3
    local data=$4
    local response_file=$(mktemp)
    local http_code=$(curl -s -w "%{http_code}" $auth -X "$method" "$url" -H "Content-Type: application/json" -d "$data" -o "$response_file")
    local body=$(cat "$response_file")
    rm -f "$response_file"
    echo "$http_code|$body"
}

# 1. Public endpoint PUT /status should be accessible without auth
status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/dispenser/123/status" -H "Content-Type: application/json" -d '{"status":"open","updated_at":"2026-01-01T00:00:00Z"}')
if [ "$status" = "401" ]; then
    fail "PUT /status should not require auth, got 401"
fi
pass "Public endpoint accessible without auth"

# 2. Protected endpoint POST /dispenser without auth -> 401
result=$(do_curl "" "POST" "$BASE_URL/dispenser" '{"flow_volume":0.064}')
http_code=$(echo "$result" | cut -d'|' -f1)
if [ "$http_code" != "401" ]; then
    fail "Protected endpoint without auth: expected 401, got $http_code"
fi
pass "Protected endpoint rejects unauthenticated request"

# 3. Protected endpoint with valid credentials -> 201 (or 409 if duplicate, but we'll use a unique flow_volume)
result=$(do_curl "$ADMIN_AUTH" "POST" "$BASE_URL/dispenser" '{"flow_volume":0.065}')
http_code=$(echo "$result" | cut -d'|' -f1)
if [ "$http_code" != "201" ]; then
    fail "Valid auth: expected 201, got $http_code"
fi
pass "Valid admin credentials allow access"

# 4. Protected endpoint with invalid credentials -> 401
result=$(do_curl "-u wrong:wrong" "POST" "$BASE_URL/dispenser" '{"flow_volume":0.066}')
http_code=$(echo "$result" | cut -d'|' -f1)
if [ "$http_code" != "401" ]; then
    fail "Invalid credentials: expected 401, got $http_code"
fi
pass "Invalid credentials rejected"

echo "✅ US-06 & US-07 PASSED"