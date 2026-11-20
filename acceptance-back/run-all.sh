#!/bin/bash
# =============================================================================
# Run all acceptance tests, always starting a fresh backend
# =============================================================================
# Launch command (from project root):
#   chmod +x user-stories/acceptance/run-all.sh && ./user-stories/acceptance/run-all.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BASE_URL="http://localhost:8080/api/v1"
ADMIN_AUTH="-u admin:admax"
BACKEND_LOG="/tmp/tap-backend.log"

is_backend_running() {
    curl -s -f -o /dev/null "$BASE_URL/dispenser" $ADMIN_AUTH 2>/dev/null
}

stop_backend() {
    echo "Stopping any existing backend..."
    PID=$(lsof -ti:8080 2>/dev/null || true)
    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null || true
        sleep 2
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" 2>/dev/null || true
        fi
        echo "Backend stopped."
    else
        echo "No backend running."
    fi
}

start_backend() {
    echo "Building project..."
    cd "$PROJECT_ROOT"
    mvn clean install -DskipTests > /dev/null 2>&1
    cd "$PROJECT_ROOT/backend"
    echo "Starting backend..."
    nohup mvn spring-boot:run > "$BACKEND_LOG" 2>&1 &

    echo "Waiting for backend..."
    for i in {1..30}; do
        if is_backend_running; then
            echo "Backend ready."
            return 0
        fi
        sleep 1
    done
    echo "Failed to start backend. Check $BACKEND_LOG"
    exit 1
}

# Always restart to ensure clean state
stop_backend
start_backend

# Run all test scripts
cd "$SCRIPT_DIR"
tests=(
    "test-us-01-create-dispenser.sh"
    "test-us-07-public-access.sh"
    "test-us-03-open-tap.sh"
    "test-us-04-close-tap.sh"
    "test-us-02-list-dispensers.sh"
    "test-us-05-spending-report.sh"
    "test-us-06-07-authentication.sh"
    "test-us-08-event-sourcing.sh"
)

for test_file in "${tests[@]}"; do
    if [ ! -f "$test_file" ]; then
        echo "Warning: $test_file not found, skipping"
        continue
    fi
    echo "=========================================="
    echo "Running $test_file"
    echo "=========================================="
    ./"$test_file"
done

# Clean up
stop_backend
echo "=========================================="
echo "All acceptance tests finished."
echo "=========================================="