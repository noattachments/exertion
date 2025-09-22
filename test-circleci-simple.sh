#!/bin/bash

# Simple CircleCI test script - Configuration validation only
# This tests the CircleCI configuration without running the full build

set -e

echo "🧪 Testing CircleCI Configuration (Simple)..."

# Test 1: Validate CircleCI config syntax
echo "1️⃣ Validating CircleCI configuration..."
if command -v circleci &> /dev/null; then
    circleci config validate
    echo "✅ CircleCI configuration is valid"
else
    echo "⚠️  CircleCI CLI not installed, skipping validation"
    echo "   Install with: curl -fLSs https://circle.ci/cli.sh | sudo bash"
    echo "   Or test online at: https://circleci.com/docs/2.0/local-cli/"
fi

# Test 2: Check Docker Compose files
echo "2️⃣ Validating Docker Compose files..."
docker-compose -f docker-compose.local.yml config > /dev/null
echo "✅ docker-compose.local.yml is valid"

docker-compose config > /dev/null
echo "✅ docker-compose.yml is valid"

# Test 3: Check if required files exist
echo "3️⃣ Checking required files..."
required_files=(
    ".circleci/config.yml"
    "docker-compose.yml"
    "docker-compose.local.yml"
    ".docker/php/Dockerfile"
    ".docker/nginx/Dockerfile"
    ".docker/mysql/Dockerfile"
    ".docker/redis/Dockerfile"
    ".docker/php/php.ini"
    ".docker/redis/redis.conf"
    ".docker/mysql/my.cnf"
    "Makefile"
    "build-and-push.sh"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Test 4: Check Makefile commands
echo "4️⃣ Testing Makefile commands..."
make help > /dev/null
echo "✅ Makefile help command works"

# Test 5: Check CircleCI config structure
echo "5️⃣ Validating CircleCI config structure..."
if [[ -f ".circleci/config.yml" ]]; then
    # Check for required sections
    if grep -q "version:" .circleci/config.yml; then
        echo "✅ CircleCI version specified"
    else
        echo "❌ CircleCI version missing"
        exit 1
    fi
    
    if grep -q "jobs:" .circleci/config.yml; then
        echo "✅ CircleCI jobs section found"
    else
        echo "❌ CircleCI jobs section missing"
        exit 1
    fi
    
    if grep -q "workflows:" .circleci/config.yml; then
        echo "✅ CircleCI workflows section found"
    else
        echo "❌ CircleCI workflows section missing"
        exit 1
    fi
fi

# Test 6: Check environment variable references
echo "6️⃣ Checking environment variable references..."
if grep -q "\${DB_PASSWORD}" .circleci/config.yml; then
    echo "✅ Database password environment variable referenced"
else
    echo "⚠️  Database password environment variable not found"
fi

if grep -q "\${REDIS_PASSWORD}" .circleci/config.yml; then
    echo "✅ Redis password environment variable referenced"
else
    echo "⚠️  Redis password environment variable not found"
fi

# Test 7: Check Docker image references
echo "7️⃣ Checking Docker image references..."
if grep -q "exertion-app" .circleci/config.yml; then
    echo "✅ App image referenced in CircleCI config"
else
    echo "⚠️  App image not referenced in CircleCI config"
fi

if grep -q "exertion-nginx" .circleci/config.yml; then
    echo "✅ Nginx image referenced in CircleCI config"
else
    echo "⚠️  Nginx image not referenced in CircleCI config"
fi

echo ""
echo "🎉 CircleCI configuration test completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Install CircleCI CLI: curl -fLSs https://circle.ci/cli.sh | sudo bash"
echo "2. Connect your repository to CircleCI"
echo "3. Set up environment variables in CircleCI project settings"
echo "4. Push to your repository to trigger the first build"
echo ""
echo "📚 Documentation:"
echo "- Setup Guide: CIRCLECI_SETUP.md"
echo "- Pipeline Overview: CI_CD_OVERVIEW.md"
echo "- Deployment Guide: DEPLOYMENT.md"
