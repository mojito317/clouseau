#!/bin/bash
set -e

# Script to reorganize commits into 3 logical groups
# Review this script before running!

BASE_COMMIT="a748cf91f2f422d5e6e3b591de0f0b6c5bb2e63e"

echo "=== Reorganizing commits since $BASE_COMMIT ==="
echo ""
echo "This will:"
echo "1. Reset to base commit (keeping all changes)"
echo "2. Create 3 new organized commits"
echo "3. You'll need to force-push after reviewing"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Save current branch name
CURRENT_BRANCH=$(git branch --show-current)

# Reset to base commit (soft reset keeps all changes staged)
echo "Resetting to base commit..."
git reset --soft $BASE_COMMIT

# Unstage everything
git reset HEAD

echo ""
echo "=== Creating Commit 1: Docker infrastructure ==="
git add docker/Dockerfile
git add docker/compose.yaml
git add docker/app.conf
git add docker/local.ini
git add .gitignore
git add Makefile

git commit -m "feat: Add Docker infrastructure and Compose setup

- Multi-stage Dockerfile with local/release build modes
- Docker Compose setup with CouchDB 3.5.1 integration
- Configuration files for Docker deployment (app.conf, local.ini)
- Makefile targets for Docker operations and testing
- Secure Erlang cookie management via generated file
- Support for both Docker and Podman Compose
- Configurable JVM memory settings via environment variables"

echo ""
echo "=== Creating Commit 2: CI/CD workflows ==="
git add .github/actions/setup/action.yaml
git add .github/workflows/build.yaml
git add .github/workflows/release.yaml

git commit -m "ci: Add Docker integration tests and release workflow

- Reusable setup action for environment configuration
- Docker integration test job in build workflow
- Integration tests with CouchDB search analyzer endpoint
- Mango and Elixir test suites against dockerized CouchDB
- Multi-platform Docker image publishing (amd64/arm64) on release
- Automated publishing to GitHub Container Registry
- Retry logic for flaky tests (3 attempts, 5min timeout)"

echo ""
echo "=== Creating Commit 3: Documentation ==="
git add docker/BUILD.md

git commit -m "docs: Add Docker build and usage documentation

- Quick start guide for pre-built images from GHCR
- Building from source instructions
- Local development workflow with Docker Compose
- Contributor guidelines for testing local changes
- Podman Compose support with configuration notes"

echo ""
echo "=== Verification ==="
echo "Commits created:"
git log --oneline $BASE_COMMIT..HEAD

echo ""
echo "All changes committed:"
git status

echo ""
echo "=== Next Steps ==="
echo "1. Review the commits: git log -p $BASE_COMMIT..HEAD"
echo "2. If satisfied, force push: git push --force-with-lease origin $CURRENT_BRANCH"
echo "3. If not satisfied, reset and try again: git reset --hard origin/$CURRENT_BRANCH"

# Made with Bob
