#!/bin/bash
# =============================================================================
# Acceptance Test: US-01 - Create a new beer dispenser
# =============================================================================
#
# Associated User Story:
#   US-01: As a festival administrator, I want to create a new beer dispenser
#          with a specific flow volume, so that I can configure the bar
#          equipment before the event starts.
#
# Scenario Description:
#   This test verifies that the POST /api/v1/dispenser endpoint correctly:
#     - Creates a dispenser with a valid positive flow volume (returns 201,
#       Location header, and correct response body).
#     - Rejects requests with missing, zero, or negative flow_volume (returns 400).
#
# Prerequisites:
#   - The backend must be running on http://localhost:8080
#   - Admin credentials: admin / admax
#   - Required tools: curl, jq
#
# Launch command (from project root):
#   chmod +x user-stories/acceptance/test-us-01-create-dispenser.sh && ./user-stories/acceptance/test-us-01-create-dispenser.sh
#
# Expected output:
#   Each step prints PASS or FAIL; final line prints "✅ US-01 PASSED" on success.
# =============================================================================
#!/bin/bash
# =============================================================================
# Acceptance Test: US-01 - Create a new beer dispenser
# =============================================================================

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080/api/v1}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-admax}"
ADMIN_AUTH="-u ${ADMIN_USER}:${ADMIN_PASS}"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

echo "=== US-01: Create dispenser ==="

# Helper to perform curl and extract status code and body
do_curl() {
    local response_file=$(mktemp)
    local http_code=$(curl -s -w "%{http_code}" $ADMIN_AUTH -X POST "$BASE_URL/dispenser" -H "Content-Type: application/json" -d "$1" -o "$response_file")
    local body=$(cat "$response_file")
    rm -f "$response_file"
    echo "$http_code|$body"
}

# 1. Positive: valid flow volume
result=$(do_curl '{"flow_volume": 0.064}')
http_code=$(echo "$result" | cut -d'|' -f1)
body=$(echo "$result" | cut -d'|' -f2-)
if [ "$http_code" != "201" ]; then fail "Expected 201, got $http_code"; fi
id=$(echo "$body" | jq -r '.id')
if [ -z "$id" ] || [ "$id" = "null" ]; then fail "Missing id in response"; fi
flow=$(echo "$body" | jq -r '.flow_volume')
if [ "$flow" != "0.064" ]; then fail "Expected flow_volume 0.064, got $flow"; fi
pass "Create valid dispenser"

# 2. Missing flow_volume
result=$(do_curl '{}')
http_code=$(echo "$result" | cut -d'|' -f1)
if [ "$http_code" != "400" ]; then fail "Expected 400 for missing flow_volume, got $http_code"; fi
pass "Missing flow_volume returns 400"

# 3. Zero flow_volume
result=$(do_curl '{"flow_volume": 0}')
http_code=$(echo "$result" | cut -d'|' -f1)
if [ "$http_code" != "400" ]; then fail "Expected 400 for zero flow_volume, got $http_code"; fi
pass "Zero flow_volume returns 400"

# 4. Negative flow_volume
result=$(do_curl '{"flow_volume": -0.1}')
http_code=$(echo "$result" | cut -d'|' -f1)
if [ "$http_code" != "400" ]; then fail "Expected 400 for negative flow_volume, got $http_code"; fi
pass "Negative flow_volume returns 400"

echo "✅ US-01 PASSED"