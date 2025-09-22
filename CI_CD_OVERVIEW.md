# CI/CD Pipeline Overview

This document provides an overview of the complete CI/CD pipeline setup for the Exertion Laravel application.

## Pipeline Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Feature       │    │   Main Branch   │    │   Release Tag   │
│   Branch        │    │                 │    │   (v1.0.0)      │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Test &        │    │   Test &        │    │   Build &       │
│   Security      │    │   Security      │    │   Deploy        │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Code Quality  │    │   Build & Push  │    │   Production    │
│   Reports       │    │   Images        │    │   Deployment    │
└─────────────────┘    └─────────┬───────┘    └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │   Staging       │
                        │   Deployment    │
                        └─────────┬───────┘
                                  │
                                  ▼
                        ┌─────────────────┐
                        │   Production    │
                        │   Deployment    │
                        └─────────────────┘
```

## Workflows

### 1. Feature Branch Workflow
**Triggers**: Push to any branch except `main`
**Jobs**:
- **Test**: PHP tests, JavaScript tests, code coverage
- **Security**: Dependency audits, vulnerability scans, code quality

### 2. Main Branch Workflow
**Triggers**: Push to `main` branch
**Jobs**:
- **Test**: Full test suite
- **Security**: Security scans
- **Build & Push**: Docker image building and registry push
- **Deploy Staging**: Automatic staging deployment
- **Deploy Production**: Production deployment (with approval)

### 3. Release Workflow
**Triggers**: Git tags matching `v*.*.*` pattern
**Jobs**:
- **Build & Push**: Versioned Docker images
- **Deploy Production**: Direct production deployment

## Key Features

### 🧪 Testing
- **PHP Tests**: Laravel feature and unit tests
- **JavaScript Tests**: Frontend component tests
- **Parallel Execution**: Tests run in parallel for speed
- **Code Coverage**: HTML coverage reports generated
- **Test Results**: JUnit XML format for CircleCI integration

### 🔒 Security
- **Dependency Audits**: Composer and NPM security scans
- **Vulnerability Scanning**: Trivy Docker image scanning
- **Code Quality**: Laravel Pint and PHPStan analysis
- **Security Thresholds**: Configurable severity levels

### 🐳 Docker Integration
- **Multi-stage Builds**: Optimized production images
- **Image Tagging**: Version and commit-based tags
- **Registry Push**: Automated Docker Hub/ECR deployment
- **Security Scanning**: Container vulnerability assessment

### 🚀 Deployment
- **Staging Environment**: Automatic staging deployments
- **Production Deployment**: Manual approval required
- **Health Checks**: Post-deployment validation
- **Rollback Support**: Easy rollback to previous versions

## Configuration Files

### Core Files
- `.circleci/config.yml` - Main CircleCI configuration
- `.circleci/env.example` - Environment variables template
- `scripts/deploy.sh` - Deployment script
- `CIRCLECI_SETUP.md` - Setup guide

### Docker Files
- `docker-compose.yml` - Production environment
- `docker-compose.local.yml` - Local development
- `Makefile` - Local development commands
- `build-and-push.sh` - Image building script

## Environment Variables

### Required
```bash
DOCKER_USERNAME=your-dockerhub-username
DOCKER_PASSWORD=your-dockerhub-token
DB_PASSWORD=exertion
REDIS_PASSWORD=redis
APP_KEY=base64:your-app-key
```

### Optional
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
SONAR_TOKEN=your-sonarqube-token
STAGING_HOST=staging.your-domain.com
PRODUCTION_HOST=your-domain.com
```

## Local Development Integration

### Makefile Commands
```bash
make circleci-test      # Run CircleCI test workflow locally
make circleci-security  # Run security scans locally
make circleci-build     # Build images for deployment
```

### Testing Locally
```bash
# Install CircleCI CLI
curl -fLSs https://circle.ci/cli.sh | sudo bash

# Validate configuration
circleci config validate

# Run jobs locally
circleci local execute --job test
circleci local execute --job security
```

## Monitoring and Notifications

### Build Status
- **Success**: Green checkmark in GitHub/GitLab
- **Failure**: Red X with detailed error logs
- **In Progress**: Yellow circle with progress indicator

### Notifications
- **Slack Integration**: Build status updates
- **Email Notifications**: Failure alerts
- **Webhook Support**: Custom integrations

### Artifacts
- **Test Reports**: JUnit XML format
- **Coverage Reports**: HTML coverage files
- **Docker Images**: Tagged and pushed to registry
- **Deployment Packages**: Ready-to-deploy configurations

## Best Practices

### Code Quality
1. **Pre-commit Hooks**: Run tests before commits
2. **Code Reviews**: Required for main branch
3. **Automated Testing**: All tests must pass
4. **Security Scans**: No high/critical vulnerabilities

### Deployment
1. **Staging First**: Always deploy to staging first
2. **Health Checks**: Validate deployments
3. **Rollback Plan**: Quick rollback capability
4. **Monitoring**: Post-deployment monitoring

### Security
1. **Secrets Management**: Use CircleCI environment variables
2. **Image Scanning**: Regular vulnerability scans
3. **Dependency Updates**: Keep dependencies current
4. **Access Control**: Limit deployment permissions

## Troubleshooting

### Common Issues
1. **Build Failures**: Check Dockerfile and dependencies
2. **Test Failures**: Review test configuration and data
3. **Security Failures**: Update dependencies or adjust thresholds
4. **Deployment Failures**: Verify credentials and network access

### Debug Commands
```bash
# Check CircleCI status
circleci status

# View job details
circleci job get <job-id>

# Retry failed job
circleci job retry <job-id>

# Download artifacts
circleci artifact download <artifact-path>
```

## Performance Optimization

### Build Speed
- **Docker Layer Caching**: Reuse unchanged layers
- **Parallel Jobs**: Run independent jobs simultaneously
- **Resource Classes**: Use appropriate compute resources
- **Dependency Caching**: Cache Composer and NPM dependencies

### Deployment Speed
- **Image Optimization**: Multi-stage builds
- **Incremental Deployments**: Only deploy changed components
- **Health Check Optimization**: Fast health validation
- **Rollback Speed**: Quick rollback mechanisms

## Future Enhancements

### Planned Features
- **Multi-environment Support**: Dev, staging, production
- **Blue-Green Deployments**: Zero-downtime deployments
- **Automated Rollbacks**: Smart rollback triggers
- **Performance Testing**: Load testing integration
- **Database Migrations**: Automated migration management

### Integration Opportunities
- **Kubernetes**: Container orchestration
- **Terraform**: Infrastructure as code
- **Prometheus**: Metrics and monitoring
- **Grafana**: Dashboards and alerting
