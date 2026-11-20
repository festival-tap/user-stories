#!/bin/bash
# =============================================================================
# Acceptance Test: US-05 - Spending report
# =============================================================================

set -euo pipefail

BASE_URL="http://localhost:8080/api/v1"
ADMIN_AUTH="-u admin:admax"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

echo "=== US-05: Spending report ==="

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

# Create dispenser
result=$(do_curl "POST" "$BASE_URL/dispenser" '{"flow_volume": 0.064}')
http_code=$(echo "$result" | cut -d'|' -f1)
body=$(echo "$result" | cut -d'|' -f2-)
if [ "$http_code" != "201" ]; then
    fail "Failed to create dispenser: HTTP $http_code, body: $body"
fi
tapId=$(echo "$body" | jq -r '.id')

# 1. Empty report (no events)
report=$(curl -s $ADMIN_AUTH "$BASE_URL/dispenser/$tapId/spending")
amount=$(echo "$report" | jq '.amount')
usages_len=$(echo "$report" | jq '.usages | length')
if (( $(echo "$amount != 0" | bc -l) )); then
    fail "Empty report: expected amount 0, got $amount"
fi
if [ "$usages_len" != "0" ]; then
    fail "Empty report: expected 0 usages, got $usages_len"
fi
pass "Empty report returns zero amount and empty usages"

# 2. Open + close session -> report with one closed session
t1=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sleep 2
t2=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
curl -s -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"open\", \"updated_at\": \"$t1\"}" > /dev/null
curl -s -X PUT "$BASE_URL/dispenser/$tapId/status" -H "Content-Type: application/json" -d "{\"status\": \"close\", \"updated_at\": \"$t2\"}" > /dev/null

report=$(curl -s $ADMIN_AUTH "$BASE_URL/dispenser/$tapId/spending")
amount=$(echo "$report" | jq '.amount')
usages_len=$(echo "$report" | jq '.usages | length')
if [ "$usages_len" != "1" ]; then
    fail "Closed session: expected 1 usage, got $usages_len"
fi
if (( $(echo "$amount <= 0" | bc -l) )); then
    fail "Closed session: expected positive amount, got $amount"
fi
pass "Closed session produces positive amount"

# 3. Open session without close -> report includes open session (closed_at null)
result=$(do_curl "POST" "$BASE_URL/dispenser" '{"flow_volume": 0.064}')
http_code=$(echo "$result" | cut -d'|' -f1)
body=$(echo "$result" | cut -d'|' -f2-)
if [ "$http_code" != "201" ]; then
    fail "Failed to create second dispenser: HTTP $http_code, body: $body"
fi
tapId2=$(echo "$body" | jq -r '.id')
t3=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
curl -s -X PUT "$BASE_URL/dispenser/$tapId2/status" -H "Content-Type: application/json" -d "{\"status\": \"open\", \"updated_at\": \"$t3\"}" > /dev/null
report=$(curl -s $ADMIN_AUTH "$BASE_URL/dispenser/$tapId2/spending")
closed_at=$(echo "$report" | jq -r '.usages[0].closed_at')
if [ "$closed_at" != "null" ]; then
    fail "Open session: expected closed_at null, got $closed_at"
fi
pass "Open session included with closed_at null"

# 4. Non-existent tap -> 404
fakeId="00000000-0000-0000-0000-000000000000"
status=$(curl -s -o /dev/null -w "%{http_code}" $ADMIN_AUTH "$BASE_URL/dispenser/$fakeId/spending")
if [ "$status" != "404" ]; then
    fail "Non-existent tap: expected 404, got $status"
fi
pass "Non-existent tap returns 404"

echo "✅ US-05 PASSED"