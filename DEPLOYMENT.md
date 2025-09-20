# Docker Deployment Guide

## File Structure

```
├── docker-compose.yml          # Production environment
├── docker-compose.local.yml    # Local development environment
├── Makefile                    # Easy command management
├── build-and-push.sh          # Registry deployment script
└── .docker/                    # Docker configuration files
    ├── php/Dockerfile
    ├── nginx/Dockerfile
    ├── mysql/Dockerfile
    └── redis/Dockerfile
```

## Quick Start with Makefile

The project includes a comprehensive Makefile for easy Docker management:

```bash
# Show all available commands
make help

# Local development
make dev          # Complete development setup
make up-local     # Start local environment
make shell        # Open shell in app container
make artisan CMD="migrate"  # Run Laravel commands

# Production
make build-prod   # Build production images
make up-prod      # Start production environment
make deploy       # Complete production deployment

# Testing
make test         # Run all tests
make test-php     # Run PHP tests only
```

## Pre-Deployment Checklist

### 1. Security Configuration

#### Generate Laravel App Key
```bash
php artisan key:generate --show
```

### 2. Image Building and Tagging

#### Build Images with Tags
```bash
# Set version and git commit
export VERSION=1.0.0
export GIT_COMMIT=$(git rev-parse --short HEAD)

# Build images
docker-compose build

# Tag for registry
docker tag exertion-app:latest your-registry/exertion-app:${VERSION}
docker tag exertion-app:latest your-registry/exertion-app:${GIT_COMMIT}
docker tag exertion-nginx:latest your-registry/exertion-nginx:${VERSION}
docker tag exertion-nginx:latest your-registry/exertion-nginx:${GIT_COMMIT}
```

### 3. Registry Push

#### Login to Registry
```bash
docker login your-registry.com
```

#### Push Images
```bash
docker push your-registry/exertion-app:${VERSION}
docker push your-registry/exertion-app:${GIT_COMMIT}
docker push your-registry/exertion-nginx:${VERSION}
docker push your-registry/exertion-nginx:${GIT_COMMIT}
```

### 4. Production Deployment

#### Use Production Compose File
```bash
# Using Makefile (recommended)
make up-prod

# Or directly with docker-compose
docker-compose up -d
```

## Security Best Practices

### ✅ Implemented
- Multi-stage builds to reduce image size
- Non-root user execution
- Health checks for all services
- Resource limits and reservations
- Network isolation
- Environment variable management

### 🔒 Additional Security Measures

#### 1. Image Scanning
```bash
# Scan images for vulnerabilities
docker scan your-registry/exertion-app:latest
docker scan your-registry/exertion-nginx:latest
```

#### 2. Secrets Management
For production, use Docker secrets or external secret management:
```yaml
# docker-compose.prod.yml
secrets:
  db_password:
    external: true
  redis_password:
    external: true
```

#### 3. SSL/TLS Configuration
- Use reverse proxy (Traefik, Nginx Proxy Manager)
- Configure SSL certificates
- Enable HTTPS redirects

#### 4. Monitoring and Logging
- Implement centralized logging
- Set up monitoring (Prometheus, Grafana)
- Configure log rotation

#### 5. Backup Strategy
- Database backups
- Volume backups
- Configuration backups

## Registry Configuration

### Docker Hub
```bash
docker tag exertion-app:latest your-username/exertion-app:latest
docker push your-username/exertion-app:latest
```

### AWS ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin your-account.dkr.ecr.us-east-1.amazonaws.com
docker tag exertion-app:latest your-account.dkr.ecr.us-east-1.amazonaws.com/exertion-app:latest
docker push your-account.dkr.ecr.us-east-1.amazonaws.com/exertion-app:latest
```

### Google GCR
```bash
gcloud auth configure-docker
docker tag exertion-app:latest gcr.io/your-project/exertion-app:latest
docker push gcr.io/your-project/exertion-app:latest
```

## CI/CD Pipeline Example

### GitHub Actions
```yaml
name: Build and Push Docker Images

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
        
      - name: Login to Registry
        uses: docker/login-action@v2
        with:
          registry: your-registry.com
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}
          
      - name: Build and Push
        uses: docker/build-push-action@v4
        with:
          context: .
          file: .docker/php/Dockerfile
          push: true
          tags: |
            your-registry.com/exertion-app:${{ github.ref_name }}
            your-registry.com/exertion-app:latest
```

## Troubleshooting

### Common Issues
1. **Permission Denied**: Check file ownership and permissions
2. **Out of Memory**: Adjust resource limits in docker-compose.prod.yml
3. **Database Connection**: Verify network connectivity and credentials
4. **SSL Issues**: Check certificate configuration and reverse proxy setup

### Health Checks
```bash
# Check container health
make health

# View logs
make logs-prod

# Or directly with docker-compose
docker-compose logs -f app
```
