#!/bin/bash

# Script to check EPMD usage in Dockerfile across all docker-related branches

echo "Checking EPMD usage in Dockerfile across all docker-related branches"
echo "======================================================================"
echo ""

BRANCHES="docker docker-clean docker-ildi"
DOCKERFILE="docker/Dockerfile"

for BRANCH in $BRANCHES; do
    echo "Branch: $BRANCH"
    echo "----------------------------------------"

    # Get all commits that modified the Dockerfile
    COMMITS=$(git log --oneline "refs/heads/$BRANCH" --all -- "$DOCKERFILE" | awk '{print $1}')

    if [ -z "$COMMITS" ]; then
        echo "  No commits found for Dockerfile"
        echo ""
        continue
    fi

    TOTAL=0
    NO_EPMD=0

    for COMMIT in $COMMITS; do
        TOTAL=$((TOTAL + 1))

        # Check if Dockerfile exists at this commit
        if git show "$COMMIT:$DOCKERFILE" > /dev/null 2>&1; then
            COMMIT_MSG=$(git log -1 --pretty=format:"%s" "$COMMIT" 2>/dev/null)
            COMMIT_DATE=$(git log -1 --pretty=format:"%cd" --date=short "$COMMIT" 2>/dev/null)

            # Check for EPMD in CMD (not just installation)
            if git show "$COMMIT:$DOCKERFILE" | grep -q "epmd -daemon"; then
                STATUS="HAS epmd -daemon"
            elif git show "$COMMIT:$DOCKERFILE" | grep -qi "epmd"; then
                STATUS="HAS epmd (install only)"
                NO_EPMD=$((NO_EPMD + 1))
                echo "  ⚠️  $COMMIT ($COMMIT_DATE) - $STATUS"
                echo "      Message: $COMMIT_MSG"
            else
                STATUS="NO EPMD"
                NO_EPMD=$((NO_EPMD + 1))
                echo "  ⚠️  $COMMIT ($COMMIT_DATE) - $STATUS"
                echo "      Message: $COMMIT_MSG"
            fi
        fi
    done

    echo ""
    echo "  Summary for $BRANCH:"
    echo "    Total commits: $TOTAL"
    echo "    Commits without epmd -daemon: $NO_EPMD"
    echo ""
done

echo "======================================================================"
echo "Done!"

# Made with Bob
