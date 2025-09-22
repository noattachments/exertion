#!/bin/bash

# Deployment script for CircleCI
# Usage: ./scripts/deploy.sh [staging|production] [version]

set -e

ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}

echo "🚀 Deploying to $ENVIRONMENT environment with version $VERSION"

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Set environment-specific variables
if [[ "$ENVIRONMENT" == "production" ]]; then
    COMPOSE_FILE="docker-compose.yml"
    HOST=${PRODUCTION_HOST:-"your-production-host.com"}
    SSH_USER=${PRODUCTION_SSH_USER:-"deploy"}
else
    COMPOSE_FILE="docker-compose.staging.yml"
    HOST=${STAGING_HOST:-"staging.your-domain.com"}
    SSH_USER=${STAGING_SSH_USER:-"deploy"}
fi

echo "📋 Deployment Configuration:"
echo "  Environment: $ENVIRONMENT"
echo "  Version: $VERSION"
echo "  Host: $HOST"
echo "  Compose File: $COMPOSE_FILE"

# Create deployment package
echo "📦 Creating deployment package..."
mkdir -p ~/deployment
cp $COMPOSE_FILE ~/deployment/docker-compose.yml
cp .env.prod.template ~/deployment/.env.template

# Create deployment script
cat > ~/deployment/deploy.sh << EOF
#!/bin/bash
set -e

echo "🔄 Updating application on $HOST..."

# Pull latest images
docker-compose pull

# Stop existing containers
docker-compose down

# Start new containers
docker-compose up -d

# Wait for services to be ready
sleep 30

# Run health checks
echo "🏥 Running health checks..."
docker-compose ps

# Run database migrations (if needed)
if [[ "$ENVIRONMENT" == "production" ]]; then
    echo "🗄️  Running database migrations..."
    docker-compose exec -T app php artisan migrate --force
fi

echo "✅ Deployment completed successfully!"
EOF

chmod +x ~/deployment/deploy.sh

# Create version file
cat > ~/deployment/version.txt << EOF
VERSION=$VERSION
ENVIRONMENT=$ENVIRONMENT
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=${CIRCLE_SHA1:-"unknown"}
EOF

echo "📁 Deployment package created:"
ls -la ~/deployment/

# If SSH deployment is configured
if [[ -n "$SSH_KEY" && -n "$HOST" ]]; then
    echo "🔐 Deploying via SSH to $HOST..."
    
    # Setup SSH key
    mkdir -p ~/.ssh
    echo "$SSH_KEY" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-keyscan -H $HOST >> ~/.ssh/known_hosts
    
    # Copy files to server
    scp -r ~/deployment/* $SSH_USER@$HOST:/opt/exertion/
    
    # Run deployment on server
    ssh $SSH_USER@$HOST "cd /opt/exertion && ./deploy.sh"
    
    echo "✅ Deployment completed successfully!"
else
    echo "📋 Deployment package ready for manual deployment:"
    echo "  Files: ~/deployment/"
    echo "  Run: ./deploy.sh on target server"
fi

# Cleanup
rm -rf ~/deployment
