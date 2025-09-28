#!/bin/bash

# Quick CircleCI Test Script
# This script runs just the tests that CircleCI runs, without full environment setup
# Use this for quick validation during development

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

echo -e "${BLUE}🧪 Quick CircleCI Test${NC}"
echo "=========================="
echo "Version: $VERSION"
echo "Git Commit: $GIT_COMMIT"
echo "=========================="
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

# Check if services are running
print_step "1️⃣ Checking if services are running"

if ! docker-compose -f docker-compose.local.yml ps | grep -q "Up"; then
    print_error "Services are not running. Please run 'make up-local' first."
    exit 1
fi

print_success "Services are running"

# Export environment variables
export VERSION=$VERSION
export GIT_COMMIT=$GIT_COMMIT
export DB_PASSWORD=$DB_PASSWORD
export REDIS_PASSWORD=$REDIS_PASSWORD
export DB_DATABASE=$DB_DATABASE
export DB_USERNAME=$DB_USERNAME
export APP_ENV=testing

# Run Laravel Tests
print_step "2️⃣ Running Laravel PHP tests"

echo "Running PHP tests with parallel execution (CircleCI environment)..."
docker-compose -f docker-compose.local.yml exec -T app php artisan test --parallel --configuration=phpunit.circleci.xml

print_success "Laravel tests passed"

# Run JavaScript Tests
print_step "3️⃣ Running JavaScript/Node tests"

echo "Running JavaScript tests..."
docker-compose -f docker-compose.local.yml exec -T app npm test

print_success "JavaScript tests passed"

# Run Security Scans
print_step "4️⃣ Running security scans"

echo "Running PHP security audit..."
docker-compose -f docker-compose.local.yml exec -T app composer audit

echo "Running Node security audit..."
docker-compose -f docker-compose.local.yml exec -T app npm audit --audit-level moderate

print_success "Security scans completed"

# Run Code Quality Checks
print_step "5️⃣ Running code quality checks"

echo "Running PHP Code Quality (Pint)..."
docker-compose -f docker-compose.local.yml exec -T app ./vendor/bin/pint --test

echo "Running PHPStan analysis..."
docker-compose -f docker-compose.local.yml exec -T app ./vendor/bin/phpstan analyse --memory-limit=2G

print_success "Code quality checks passed"

echo ""
print_success "🎉 All CircleCI tests passed!"
echo ""
echo -e "${BLUE}📋 Your changes are ready for CircleCI!${NC}"
