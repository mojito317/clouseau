#!/bin/bash

# Simple script to check EPMD usage in Dockerfile across reflog entries

BRANCH="docker-ildi"
DOCKERFILE="docker/Dockerfile"

echo "Checking EPMD usage in $DOCKERFILE across reflog of $BRANCH"
echo "============================================================"
echo ""

# Save current commit
ORIGINAL_COMMIT=$(git rev-parse HEAD)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Current branch: $CURRENT_BRANCH"
echo "Current commit: $ORIGINAL_COMMIT"
echo ""

# Get reflog entries
REFLOG_ENTRIES=$(git reflog show "$BRANCH" | awk '{print $1}')
TOTAL=$(echo "$REFLOG_ENTRIES" | wc -l | tr -d ' ')

echo "Found $TOTAL reflog entries"
echo ""

COUNT=0
NO_EPMD_COUNT=0

for COMMIT in $REFLOG_ENTRIES; do
    COUNT=$((COUNT + 1))

    # Get commit info
    COMMIT_MSG=$(git log -1 --pretty=format:"%s" "$COMMIT" 2>/dev/null || echo "N/A")
    COMMIT_DATE=$(git log -1 --pretty=format:"%cd" --date=short "$COMMIT" 2>/dev/null || echo "N/A")

    # Check if Dockerfile exists at this commit
    if git show "$COMMIT:$DOCKERFILE" > /dev/null 2>&1; then
        # Check for EPMD
        if git show "$COMMIT:$DOCKERFILE" | grep -qi "epmd"; then
            echo "[$COUNT/$TOTAL] $COMMIT ($COMMIT_DATE) - HAS EPMD"
            echo "  Message: $COMMIT_MSG"
        else
            echo "[$COUNT/$TOTAL] $COMMIT ($COMMIT_DATE) - NO EPMD ⚠️"
            echo "  Message: $COMMIT_MSG"
            NO_EPMD_COUNT=$((NO_EPMD_COUNT + 1))
        fi
    else
        echo "[$COUNT/$TOTAL] $COMMIT ($COMMIT_DATE) - No Dockerfile"
        echo "  Message: $COMMIT_MSG"
    fi
    echo ""
done

echo "============================================================"
echo "Summary:"
echo "  Total commits: $TOTAL"
echo "  Commits without EPMD: $NO_EPMD_COUNT"
echo ""

if [ $NO_EPMD_COUNT -gt 0 ]; then
    echo "Found $NO_EPMD_COUNT commit(s) without EPMD that need testing!"
else
    echo "All commits use EPMD in Dockerfile."
fi

# Made with Bob
