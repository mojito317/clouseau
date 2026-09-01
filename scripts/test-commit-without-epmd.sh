#!/bin/bash

# Script to test the specific commit without EPMD

set -e

COMMIT="a748cf91"
DOCKERFILE="docker/Dockerfile"
COMPOSE_FILE="docker/compose.yaml"

echo "Testing commit without EPMD: $COMMIT"
echo "========================================"
echo ""

# Save current state
ORIGINAL_COMMIT=$(git rev-parse HEAD)
echo "Saving current commit: $ORIGINAL_COMMIT"

# Checkout the commit
echo "Checking out commit $COMMIT..."
git checkout "$COMMIT"

# Show commit info
echo ""
echo "Commit details:"
git log -1 --pretty=format:"Date: %ai%nAuthor: %an%nMessage: %s%n" "$COMMIT"
echo ""

# Verify no EPMD in Dockerfile
echo ""
echo "Checking Dockerfile for EPMD..."
if grep -qi "epmd" "$DOCKERFILE"; then
    echo "ERROR: EPMD found in Dockerfile! This should not happen."
    git checkout "$ORIGINAL_COMMIT"
    exit 1
else
    echo "✓ Confirmed: No EPMD in Dockerfile"
fi

echo ""
echo "Dockerfile content:"
echo "-------------------"
cat "$DOCKERFILE"
echo "-------------------"
echo ""

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: compose.yaml not found at this commit"
    git checkout "$ORIGINAL_COMMIT"
    exit 1
fi

echo "Starting Docker integration test..."
echo ""

# Stop any running containers
echo "1. Stopping any running containers..."
docker compose -f "$COMPOSE_FILE" down || true
sleep 2

# Start containers
echo ""
echo "2. Starting Docker containers..."
if ! docker compose -f "$COMPOSE_FILE" up -d; then
    echo "ERROR: Failed to start docker compose"
    git checkout "$ORIGINAL_COMMIT"
    exit 1
fi

# Wait for services
echo ""
echo "3. Waiting for services to be ready (30 seconds)..."
sleep 30

# Run integration test
echo ""
echo "4. Running integration test..."
if make docker-test-integration; then
    echo ""
    echo "✓ Integration test PASSED!"
    TEST_RESULT="PASSED"
else
    echo ""
    echo "✗ Integration test FAILED!"
    TEST_RESULT="FAILED"
fi

# Cleanup
echo ""
echo "5. Cleaning up..."
docker compose -f "$COMPOSE_FILE" down

# Return to original commit
echo ""
echo "Returning to original commit..."
git checkout "$ORIGINAL_COMMIT"

echo ""
echo "========================================"
echo "Test Result: $TEST_RESULT"
echo "========================================"

if [ "$TEST_RESULT" = "FAILED" ]; then
    exit 1
fi

# Made with Bob
