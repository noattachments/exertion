# Local CircleCI Testing Guide

This guide helps you test your changes locally in the same environment that CircleCI uses, ensuring your tests pass before pushing to the repository.

## Quick Start

### Option 1: Quick Test (Recommended for development)
```bash
# Start your services first
make up-local

# Run the same tests that CircleCI runs
make test-circleci-quick
```

### Option 2: Full Test (Complete CircleCI simulation)
```bash
# This will set up the entire environment and run all tests
make test-circleci-full
```

## Available Commands

| Command | Description | When to Use |
|---------|-------------|-------------|
| `make test-circleci-quick` | Quick test (requires services running) | During development, after making changes |
| `make test-circleci-full` | Full CircleCI simulation | Before pushing important changes |
| `./test-circleci-quick.sh` | Direct script execution | When you want more control |
| `./test-circleci-local.sh` | Full simulation script | Complete environment testing |

## What Each Test Does

### Quick Test (`test-circleci-quick`)
- ✅ Checks if services are running
- ✅ Runs Laravel PHP tests (parallel execution)
- ✅ Runs JavaScript/Node tests
- ✅ Runs security scans (composer audit, npm audit)
- ✅ Runs code quality checks (Pint, PHPStan)

### Full Test (`test-circleci-full`)
- ✅ All quick test features
- ✅ Validates CircleCI configuration
- ✅ Validates Docker Compose files
- ✅ Builds Docker images from scratch
- ✅ Starts all services
- ✅ Waits for services to be ready
- ✅ Runs database migrations
- ✅ Generates code coverage reports
- ✅ Tests build and push process

## Environment Variables

The test scripts use the same environment variables as CircleCI:

```bash
VERSION="test-$(git rev-parse --short HEAD)"
GIT_COMMIT=$(git rev-parse --short HEAD)
DB_PASSWORD="exertion"
REDIS_PASSWORD="redis"
DB_DATABASE="exertion_test"
DB_USERNAME="exertion_user"
APP_ENV="testing"
```

## Troubleshooting

### Services Not Running
```bash
# Start services first
make up-local

# Then run tests
make test-circleci-quick
```

### Database Connection Issues
```bash
# Check if database is ready
docker-compose -f docker-compose.local.yml exec database mysqladmin ping -h localhost -u root -p${DB_PASSWORD}

# Check database logs
docker-compose -f docker-compose.local.yml logs database
```

### Redis Connection Issues
```bash
# Check if Redis is ready
docker-compose -f docker-compose.local.yml exec redis redis-cli -a ${REDIS_PASSWORD} ping

# Check Redis logs
docker-compose -f docker-compose.local.yml logs redis
```

### Test Failures
```bash
# Run tests with more verbose output
docker-compose -f docker-compose.local.yml exec app php artisan test --verbose

# Check application logs
docker-compose -f docker-compose.local.yml logs app
```

## CircleCI vs Local Differences

| Aspect | CircleCI | Local |
|--------|----------|-------|
| Environment | Fresh Ubuntu container | Your local machine |
| Docker Images | Built from scratch | May use cached layers |
| Database | Fresh test database | May have existing data |
| File Permissions | Container user | Your local user |
| Network | Container network | Local Docker network |

## Best Practices

1. **Run quick tests frequently** during development
2. **Run full tests** before pushing important changes
3. **Check the coverage report** in `storage/coverage/` after full tests
4. **Monitor CircleCI logs** for any environment-specific issues
5. **Keep your local environment clean** by running `make down-local` between tests

## Common Issues and Solutions

### Issue: Tests pass locally but fail on CircleCI
**Solution**: Run `make test-circleci-full` to simulate the exact CircleCI environment

### Issue: Database connection errors
**Solution**: Ensure services are running and wait for them to be ready:
```bash
make up-local
# Wait a few seconds
make test-circleci-quick
```

### Issue: Permission errors
**Solution**: Check file permissions and ensure Docker has proper access:
```bash
# Fix permissions
sudo chown -R $USER:$USER .
# Rebuild images
make build-local
```

### Issue: Cache issues
**Solution**: Clear Docker cache and rebuild:
```bash
make down-local
docker system prune -f
make build-local
make up-local
```

## Integration with Development Workflow

1. **During development**: Use `make test-circleci-quick` after making changes
2. **Before committing**: Run `make test-circleci-full` to ensure everything works
3. **Before pushing**: Double-check with `make test-circleci-quick` one more time
4. **After CircleCI fails**: Use `make test-circleci-full` to reproduce the issue locally

## Scripts Location

- `test-circleci-quick.sh` - Quick test script
- `test-circleci-local.sh` - Full CircleCI simulation
- `test-circleci.sh` - Original simple validation script
- `test-circleci-simple.sh` - Configuration validation only

## Need Help?

If you encounter issues that aren't covered here:

1. Check the CircleCI logs for specific error messages
2. Compare your local environment with CircleCI's environment
3. Run `make test-circleci-full` to get the complete picture
4. Check the coverage report for any missed test cases
