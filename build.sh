#!/bin/bash
set -e

echo "Building Base Node Docker images with BuildKit..."
echo "================================================"

# Enable Docker BuildKit for better caching and parallel builds
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build images with cache
echo ""
echo "Building base-execution (Nethermind)..."
docker-compose build base-execution

echo ""
echo "Building base-op-node..."
docker-compose build base-op-node

echo ""
echo "================================================"
echo "Build complete! Images ready:"
echo "  - base-execution:latest"
echo "  - base-op-node:latest"
echo ""
echo "To start the stack: docker-compose up -d"
echo "To rebuild a specific service: docker-compose build <service-name>"
