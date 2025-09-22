#!/bin/bash

# Simple CircleCI test script
# This tests the basic functionality without the full build process

set -e

echo "🧪 Testing CircleCI Configuration..."

# Test 1: Validate CircleCI config syntax
echo "1️⃣ Validating CircleCI configuration..."
if command -v circleci &> /dev/null; then
    circleci config validate
    echo "✅ CircleCI configuration is valid"
else
    echo "⚠️  CircleCI CLI not installed, skipping validation"
    echo "   Install with: curl -fLSs https://circle.ci/cli.sh | sudo bash"
fi

# Test 2: Check Docker Compose files
echo "2️⃣ Validating Docker Compose files..."
docker-compose -f docker-compose.local.yml config > /dev/null
echo "✅ docker-compose.local.yml is valid"

docker-compose config > /dev/null
echo "✅ docker-compose.yml is valid"

# Test 3: Test Docker builds (without running)
echo "3️⃣ Testing Docker builds..."
echo "Building database image..."
docker-compose -f docker-compose.local.yml build database

echo "Building Redis image..."
docker-compose -f docker-compose.local.yml build redis

echo "Building PHP image (this may take a while)..."
docker-compose -f docker-compose.local.yml build app

echo "Building Nginx image..."
docker-compose -f docker-compose.local.yml build webserver

echo "✅ All Docker images built successfully"

# Test 4: Test services startup
echo "4️⃣ Testing services startup..."
docker-compose -f docker-compose.local.yml up -d

echo "Waiting for services to be ready..."
sleep 10

# Test 5: Check service health
echo "5️⃣ Checking service health..."
docker-compose -f docker-compose.local.yml ps

# Test 6: Test Laravel commands
echo "6️⃣ Testing Laravel commands..."
docker-compose -f docker-compose.local.yml exec -T app php artisan --version
docker-compose -f docker-compose.local.yml exec -T app php artisan route:list

# Test 7: Test database connection
echo "7️⃣ Testing database connection..."
docker-compose -f docker-compose.local.yml exec -T database mysqladmin ping -h localhost -u root -p${DB_PASSWORD:-exertion}

# Test 8: Test Redis connection
echo "8️⃣ Testing Redis connection..."
docker-compose -f docker-compose.local.yml exec -T redis redis-cli -a ${REDIS_PASSWORD:-redis} ping

echo "✅ All tests passed!"

# Cleanup
echo "🧹 Cleaning up..."
docker-compose -f docker-compose.local.yml down

echo "🎉 CircleCI configuration test completed successfully!"
