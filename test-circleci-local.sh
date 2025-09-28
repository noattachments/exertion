#!/bin/bash

# CircleCI Local Test Script
# This script mimics CircleCI's exact environment and workflow locally
# Run this before pushing to ensure your changes will pass on CircleCI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="test-$(git rev-parse --short HEAD)"
GIT_COMMIT=$(git rev-parse --short HEAD)
DB_PASSWORD="exertion"
REDIS_PASSWORD="redis"
DB_DATABASE="exertion_test"
DB_USERNAME="exertion_user"

echo -e "${BLUE}🚀 CircleCI Local Test Environment${NC}"
echo "=================================="
echo "Version: $VERSION"
echo "Git Commit: $GIT_COMMIT"
echo "Database: $DB_DATABASE"
echo "=================================="
echo ""

# Function to print step headers
print_step() {
    echo -e "${YELLOW}$1${NC}"
    echo "----------------------------------------"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to cleanup on exit
cleanup() {
    print_step "🧹 Cleanup"
    echo "Stopping all services..."
    docker-compose -f docker-compose.local.yml down -v 2>/dev/null || true
    echo "Removing test images..."
    docker rmi exertion-app:$VERSION exertion-nginx:$VERSION 2>/dev/null || true
    print_success "Cleanup completed"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Step 1: Environment Setup
print_step "1️⃣ Setting up CircleCI-like environment"

# Export environment variables (mimicking CircleCI)
export VERSION=$VERSION
export GIT_COMMIT=$GIT_COMMIT
export DB_PASSWORD=$DB_PASSWORD
export REDIS_PASSWORD=$REDIS_PASSWORD
export DB_DATABASE=$DB_DATABASE
export DB_USERNAME=$DB_USERNAME
export APP_ENV=testing

print_success "Environment variables set"

# Step 2: Validate CircleCI Configuration
print_step "2️⃣ Validating CircleCI configuration"

if command -v circleci &> /dev/null; then
    circleci config validate
    print_success "CircleCI configuration is valid"
else
    echo "⚠️  CircleCI CLI not installed, skipping validation"
    echo "   Install with: curl -fLSs https://circle.ci/cli.sh | sudo bash"
fi

# Step 3: Validate Docker Compose Files
print_step "3️⃣ Validating Docker Compose files"

docker-compose -f docker-compose.local.yml config > /dev/null
print_success "docker-compose.local.yml is valid"

docker-compose config > /dev/null
print_success "docker-compose.yml is valid"

# Step 4: Build Images (CircleCI Test Job)
print_step "4️⃣ Building Docker images (CircleCI test job)"

echo "Building all services..."
docker-compose -f docker-compose.local.yml build --no-cache

print_success "All Docker images built successfully"

# Step 5: Start Services
print_step "5️⃣ Starting services"

echo "Starting all services..."
docker-compose -f docker-compose.local.yml up -d

print_success "Services started"

# Step 6: Wait for Services (CircleCI wait-for-services command)
print_step "6️⃣ Waiting for services to be ready"

echo "Waiting for database..."
timeout 60 bash -c 'until docker-compose -f docker-compose.local.yml exec -T database mysqladmin ping -h localhost -u root -p${DB_PASSWORD} --silent; do sleep 2; done'
print_success "Database is ready"

echo "Waiting for Redis..."
timeout 60 bash -c 'until docker-compose -f docker-compose.local.yml exec -T redis redis-cli -a ${REDIS_PASSWORD} ping | grep -q PONG; do sleep 2; done'
print_success "Redis is ready"

# Step 7: Run Database Migrations
print_step "7️⃣ Running database migrations"

echo "Running migrations..."
docker-compose -f docker-compose.local.yml exec -T app php artisan migrate --force
print_success "Database migrations completed"

# Step 8: Run Laravel Tests (CircleCI run-laravel-tests command)
print_step "8️⃣ Running Laravel PHP tests"

echo "Running PHP tests with parallel execution (CircleCI environment)..."
docker-compose -f docker-compose.local.yml exec -T app php artisan test --parallel --configuration=phpunit.circleci.xml

print_success "Laravel tests passed"

# Step 9: Run JavaScript Tests (CircleCI run-javascript-tests command)
print_step "9️⃣ Running JavaScript/Node tests"

echo "Running JavaScript tests..."
docker-compose -f docker-compose.local.yml exec -T app npm test

print_success "JavaScript tests passed"

# Step 10: Generate Code Coverage
print_step "🔟 Generating code coverage"

echo "Generating coverage report..."
docker-compose -f docker-compose.local.yml exec -T app php artisan test --coverage --coverage-html=storage/coverage --configuration=phpunit.circleci.xml

print_success "Code coverage generated"

# Step 11: Security Scans (CircleCI security-scan command)
print_step "1️⃣1️⃣ Running security scans"

echo "Running PHP security audit..."
docker-compose -f docker-compose.local.yml exec -T app composer audit

echo "Running Node security audit..."
docker-compose -f docker-compose.local.yml exec -T app npm audit --audit-level moderate

print_success "Security scans completed"

# Step 12: Code Quality Checks
print_step "1️⃣2️⃣ Running code quality checks"

echo "Running PHP Code Quality (Pint)..."
docker-compose -f docker-compose.local.yml exec -T app ./vendor/bin/pint --test

echo "Running PHPStan analysis..."
docker-compose -f docker-compose.local.yml exec -T app ./vendor/bin/phpstan analyse --memory-limit=2G

print_success "Code quality checks passed"

# Step 13: Test Build and Push Process
print_step "1️⃣3️⃣ Testing build and push process"

echo "Testing image tagging..."
docker tag exertion-app:$VERSION exertion-app:latest
docker tag exertion-nginx:$VERSION exertion-nginx:latest

print_success "Image tagging completed"

# Step 14: Final Status Check
print_step "1️⃣4️⃣ Final status check"

echo "Service status:"
docker-compose -f docker-compose.local.yml ps

echo ""
echo "Test results summary:"
echo "- ✅ Docker Compose validation"
echo "- ✅ Docker image builds"
echo "- ✅ Service startup and health checks"
echo "- ✅ Database migrations"
echo "- ✅ Laravel PHP tests"
echo "- ✅ JavaScript tests"
echo "- ✅ Code coverage generation"
echo "- ✅ Security scans"
echo "- ✅ Code quality checks"
echo "- ✅ Build and push process"

echo ""
print_success "🎉 All CircleCI tests passed locally!"
echo ""
echo -e "${BLUE}📋 Your changes are ready for CircleCI!${NC}"
echo "You can now safely push your changes to trigger the CircleCI pipeline."
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "- This script mimics CircleCI's exact environment"
echo "- If tests pass here, they should pass on CircleCI"
echo "- Check the coverage report in storage/coverage/"
echo "- Monitor CircleCI logs for any environment-specific issues"
