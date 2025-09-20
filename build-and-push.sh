#!/bin/bash

# Build and Push Docker Images Script
# Usage: ./build-and-push.sh [registry] [version]

set -e

# Configuration
REGISTRY=${1:-"your-registry.com"}
VERSION=${2:-$(git describe --tags --always)}
GIT_COMMIT=$(git rev-parse --short HEAD)

echo "🚀 Building and pushing Docker images..."
echo "Registry: $REGISTRY"
echo "Version: $VERSION"
echo "Git Commit: $GIT_COMMIT"

# Export environment variables
export VERSION=$VERSION
export GIT_COMMIT=$GIT_COMMIT

# Build images
echo "📦 Building images..."
docker-compose -f docker-compose.local.yml build

# Tag images for registry
echo "🏷️  Tagging images..."
docker tag exertion-app:latest $REGISTRY/exertion-app:$VERSION
docker tag exertion-app:latest $REGISTRY/exertion-app:$GIT_COMMIT
docker tag exertion-app:latest $REGISTRY/exertion-app:latest

docker tag exertion-nginx:latest $REGISTRY/exertion-nginx:$VERSION
docker tag exertion-nginx:latest $REGISTRY/exertion-nginx:$GIT_COMMIT
docker tag exertion-nginx:latest $REGISTRY/exertion-nginx:latest

# Login to registry (uncomment and configure as needed)
# echo "🔐 Logging into registry..."
# docker login $REGISTRY

# Push images
echo "⬆️  Pushing images..."
docker push $REGISTRY/exertion-app:$VERSION
docker push $REGISTRY/exertion-app:$GIT_COMMIT
docker push $REGISTRY/exertion-app:latest

docker push $REGISTRY/exertion-nginx:$VERSION
docker push $REGISTRY/exertion-nginx:$GIT_COMMIT
docker push $REGISTRY/exertion-nginx:latest

echo "✅ Successfully built and pushed images!"
echo "Images pushed:"
echo "  - $REGISTRY/exertion-app:$VERSION"
echo "  - $REGISTRY/exertion-app:$GIT_COMMIT"
echo "  - $REGISTRY/exertion-app:latest"
echo "  - $REGISTRY/exertion-nginx:$VERSION"
echo "  - $REGISTRY/exertion-nginx:$GIT_COMMIT"
echo "  - $REGISTRY/exertion-nginx:latest"
