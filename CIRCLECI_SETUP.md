# CircleCI Setup Guide

This guide will help you set up CircleCI for your Laravel application with Docker support.

## Prerequisites

1. **CircleCI Account**: Sign up at [circleci.com](https://circleci.com)
2. **GitHub/GitLab Repository**: Your code must be in a Git repository
3. **Docker Hub Account**: For pushing Docker images (or other registry)

## Setup Steps

### 1. Connect Repository to CircleCI

1. Go to [CircleCI Dashboard](https://app.circleci.com/)
2. Click "Add Projects"
3. Find your repository and click "Set Up Project"
4. Choose "Fastest" setup method
5. CircleCI will automatically detect the `.circleci/config.yml` file

### 2. Configure Environment Variables

Go to your project settings in CircleCI and add these environment variables:

#### Required Variables:
```bash
# Docker Registry
DOCKER_USERNAME=your-dockerhub-username
DOCKER_PASSWORD=your-dockerhub-password-or-token

# Database (for testing)
DB_PASSWORD=exertion
DB_DATABASE=exertion_test
DB_USERNAME=exertion_user
DB_ROOT_PASSWORD=root

# Redis (for testing)
REDIS_PASSWORD=redis

# Application
APP_ENV=testing
APP_DEBUG=false
APP_KEY=base64:your-test-app-key-here
```

#### Optional Variables:
```bash
# Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK

# Code Quality
SONAR_TOKEN=your-sonarqube-token
CODECOV_TOKEN=your-codecov-token
```

### 3. Generate Laravel App Key

Generate a test application key for CircleCI:

```bash
# Generate a new app key
php artisan key:generate --show

# Or use this command to generate a base64 key
openssl rand -base64 32
```

### 4. Configure Docker Hub (or other registry)

#### Docker Hub:
1. Go to [Docker Hub](https://hub.docker.com/)
2. Create a new repository (e.g., `your-username/exertion-app`)
3. Generate an access token in Account Settings > Security
4. Use the access token as `DOCKER_PASSWORD`

#### AWS ECR:
```bash
# Set these environment variables in CircleCI
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=us-east-1
ECR_REGISTRY=your-account.dkr.ecr.us-east-1.amazonaws.com
```

## Workflow Overview

The CircleCI configuration includes three main workflows:

### 1. Test and Security (Feature Branches)
- Runs on all branches except `main`
- Executes PHP and JavaScript tests
- Runs security scans
- Generates code coverage reports

### 2. Build and Deploy (Main Branch)
- Runs on `main` branch
- Executes tests and security scans
- Builds and pushes Docker images
- Deploys to staging environment
- Deploys to production (on success)

### 3. Tag Deployment (Releases)
- Runs on version tags (e.g., `v1.0.0`)
- Builds and pushes Docker images
- Deploys directly to production

## Jobs Explained

### Test Job
- Builds Docker images using local compose file
- Starts all services (app, database, redis, nginx)
- Waits for services to be ready
- Runs database migrations
- Executes PHP and JavaScript tests
- Generates code coverage reports
- Stores test results and artifacts

### Security Job
- Builds Docker images
- Runs security scans:
  - Composer audit (PHP dependencies)
  - NPM audit (JavaScript dependencies)
  - Trivy (Docker image vulnerabilities)
- Runs code quality checks:
  - Laravel Pint (code formatting)
  - PHPStan (static analysis)

### Build and Push Job
- Builds production Docker images
- Tags images with version and git commit
- Pushes to Docker registry
- Updates deployment manifests
- Stores deployment artifacts

### Deploy Jobs
- Deploys to staging environment
- Runs smoke tests
- Deploys to production (with approval)
- Runs production health checks

## Local Testing

You can test CircleCI workflows locally:

```bash
# Install CircleCI CLI
curl -fLSs https://circle.ci/cli.sh | sudo bash

# Validate configuration
circleci config validate

# Test locally (requires Docker)
circleci local execute --job test
circleci local execute --job security
```

## Customization

### Adding New Tests
Add new test commands to the `run-laravel-tests` or `run-javascript-tests` commands in the config.

### Adding New Security Scans
Add new security tools to the `security-scan` command.

### Custom Deployment
Modify the `deploy-staging` and `deploy-production` jobs to match your deployment strategy.

### Notification Integration
Add notification steps to jobs:

```yaml
- run:
    name: "Notify Slack"
    command: |
      curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"Deployment successful!"}' \
        $SLACK_WEBHOOK_URL
```

## Troubleshooting

### Common Issues

1. **Docker Build Fails**
   - Check Dockerfile syntax
   - Verify all required files are present
   - Check build context size

2. **Tests Fail**
   - Verify database connection
   - Check environment variables
   - Review test configuration

3. **Security Scans Fail**
   - Update dependencies
   - Review security advisories
   - Configure scan thresholds

4. **Deployment Fails**
   - Check registry credentials
   - Verify deployment scripts
   - Review environment configuration

### Debug Commands

```bash
# Check CircleCI status
circleci status

# View job logs
circleci job get <job-id>

# Retry failed job
circleci job retry <job-id>
```

## Best Practices

1. **Keep Secrets Secure**: Never commit secrets to the repository
2. **Use Environment Variables**: Store all sensitive data in CircleCI environment variables
3. **Optimize Build Times**: Use Docker layer caching and parallel jobs
4. **Monitor Resource Usage**: Set appropriate resource limits
5. **Regular Updates**: Keep dependencies and base images updated
6. **Test Locally**: Use CircleCI CLI to test changes locally

## Advanced Features

### Parallel Jobs
```yaml
jobs:
  - test-php
  - test-js
  - security-scan
```

### Conditional Execution
```yaml
- run:
    name: "Deploy to staging"
    command: deploy-staging.sh
    when:
      condition: << pipeline.parameters.deploy-staging >>
```

### Matrix Builds
```yaml
- test:
    matrix:
      parameters:
        php-version: ["8.1", "8.2", "8.3"]
```

## Support

- [CircleCI Documentation](https://circleci.com/docs/)
- [CircleCI Community](https://discuss.circleci.com/)
- [Laravel Testing Guide](https://laravel.com/docs/testing)
