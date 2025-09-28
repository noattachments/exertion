# Exertion Application Makefile
# Provides easy commands for Docker development and production deployment

.PHONY: help build-local build-prod up-local up-prod down-local down-prod restart-local restart-prod logs-local logs-prod shell shell-php test test-php artisan migrate seed fresh clean build-push test-circleci test-circleci-quick test-circleci-full show-config

# Default target
help: ## Show this help message
	@echo "Exertion Application - Docker Management"
	@echo "========================================"
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Load .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Environment variables
VERSION ?= $(shell git describe --tags --always 2>/dev/null || echo "latest")
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")
REGISTRY ?= $(REGISTRY_SRC)

# Local Development Commands
build-local: ## Build Docker images for local development
	@echo "🔨 Building local development images..."
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose -f docker-compose.local.yml build

up-local: ## Start local development environment
	@echo "🚀 Starting local development environment..."
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose -f docker-compose.local.yml up -d
	@echo "✅ Local environment started!"
	@echo "🌐 Application: http://localhost:8080"
	@echo "🗄️  Database: localhost:3306"
	@echo "🔴 Redis: localhost:6379"

down-local: ## Stop local development environment
	@echo "🛑 Stopping local development environment..."
	@docker-compose -f docker-compose.local.yml down

restart-local: ## Restart local development environment
	@echo "🔄 Restarting local development environment..."
	@$(MAKE) down-local
	@$(MAKE) up-local

logs-local: ## Show logs for local development environment
	@docker-compose -f docker-compose.local.yml logs -f

# Production Commands
build-prod: ## Build Docker images for production
	@echo "🔨 Building production images..."
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose build

up-prod: ## Start production environment
	@echo "🚀 Starting production environment..."
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose up -d
	@echo "✅ Production environment started!"

down-prod: ## Stop production environment
	@echo "🛑 Stopping production environment..."
	@docker-compose down

restart-prod: ## Restart production environment
	@echo "🔄 Restarting production environment..."
	@$(MAKE) down-prod
	@$(MAKE) up-prod

logs-prod: ## Show logs for production environment
	@docker-compose logs -f

# Development Tools
shell: ## Open shell in the app container (local)
	@echo "🐚 Opening shell in local app container..."
	@docker-compose -f docker-compose.local.yml exec app sh

shell-php: ## Open PHP shell in the app container (local)
	@echo "🐚 Opening PHP shell in local app container..."
	@docker-compose -f docker-compose.local.yml exec app php artisan tinker

# Laravel Commands
artisan: ## Run Laravel artisan command (usage: make artisan CMD="migrate")
	@echo "🎨 Running Laravel artisan: $(CMD)"
	@docker-compose -f docker-compose.local.yml exec app php artisan $(CMD)

migrate: ## Run database migrations
	@echo "🗄️  Running database migrations..."
	@docker-compose -f docker-compose.local.yml exec app php artisan migrate

migrate-fresh: ## Fresh migration with seeding
	@echo "🗄️  Running fresh migrations with seeding..."
	@docker-compose -f docker-compose.local.yml exec app php artisan migrate:fresh --seed

seed: ## Run database seeding
	@echo "🌱 Running database seeding..."
	@docker-compose -f docker-compose.local.yml exec app php artisan db:seed

# Testing Commands
test: ## Run all tests
	@echo "🧪 Running all tests..."
	@docker-compose -f docker-compose.local.yml exec app php artisan test

test-php: ## Run PHP tests only
	@echo "🧪 Running PHP tests..."
	@docker-compose -f docker-compose.local.yml exec app ./vendor/bin/pest

test-watch: ## Run tests in watch mode
	@echo "🧪 Running tests in watch mode..."
	@docker-compose -f docker-compose.local.yml exec app ./vendor/bin/pest --watch

# Utility Commands
clean: ## Clean up Docker resources
	@echo "🧹 Cleaning up Docker resources..."
	@docker-compose -f docker-compose.local.yml down -v
	@docker-compose down -v
	@docker system prune -f
	@echo "✅ Cleanup completed!"

status: ## Show status of all containers
	@echo "📊 Container Status:"
	@echo "Local Environment:"
	@docker-compose -f docker-compose.local.yml ps
	@echo ""
	@echo "Production Environment:"
	@docker-compose ps

# Build and Push Commands
build-push: ## Build and push images to registry
	@echo "🚀 Building and pushing images to registry..."
	@./build-and-push.sh $(REGISTRY) $(VERSION)

# Database Commands
db-shell: ## Open MySQL shell
	@echo "🗄️  Opening MySQL shell..."
	@docker-compose -f docker-compose.local.yml exec database mysql -u root -p

redis-cli: ## Open Redis CLI
	@echo "🔴 Opening Redis CLI..."
	@docker-compose -f docker-compose.local.yml exec redis redis-cli -a $(REDIS_PASSWORD:-redis)

# Quick Setup Commands
setup: ## Initial setup for local development
	@echo "⚙️  Setting up local development environment..."
	@$(MAKE) build-local
	@$(MAKE) up-local
	@echo "⏳ Waiting for services to be ready..."
	@sleep 10
	@$(MAKE) migrate
	@echo "✅ Setup completed! Visit http://localhost:8080"

# Health Checks
health: ## Check health of all services
	@echo "🏥 Checking service health..."
	@echo "Local Environment:"
	@docker-compose -f docker-compose.local.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "Production Environment:"
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Development Workflow
dev: ## Start development workflow (build, up, migrate)
	@echo "🚀 Starting development workflow..."
	@$(MAKE) build-local
	@$(MAKE) up-local
	@echo "⏳ Waiting for services..."
	@sleep 15
	@$(MAKE) migrate
	@echo "✅ Development environment ready!"
	@echo "🌐 Application: http://localhost:8080"

# Production Deployment
deploy: ## Deploy to production
	@echo "🚀 Deploying to production..."
	@$(MAKE) build-prod
	@$(MAKE) up-prod
	@echo "✅ Production deployment completed!"

# Show environment info
info: ## Show environment information
	@echo "📋 Environment Information:"
	@echo "Version: $(VERSION)"
	@echo "Git Commit: $(GIT_COMMIT)"
	@echo "Registry: $(REGISTRY)"
	@echo ""
	@echo "Docker Compose Files:"
	@echo "  Local: docker-compose.local.yml"
	@echo "  Production: docker-compose.yml"

# CircleCI Integration
circleci-test: ## Run tests in CircleCI environment
	@echo "🔄 Running CircleCI test workflow..."
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose -f docker-compose.local.yml build
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose -f docker-compose.local.yml up -d
	@echo "⏳ Waiting for services to be ready..."
	@sleep 30
	@echo "🗄️  Waiting for database to be ready..."
	@for i in {1..30}; do \
		if docker-compose -f docker-compose.local.yml exec -T database mysqladmin ping -h localhost -u root -proot --silent 2>/dev/null; then \
			echo "✅ Database is ready!"; \
			break; \
		fi; \
		echo "⏳ Waiting for database... ($$i/30)"; \
		sleep 2; \
	done
	@echo "🔴 Waiting for Redis to be ready..."
	@for i in {1..30}; do \
		if docker-compose -f docker-compose.local.yml exec -T redis redis-cli -a redis ping 2>/dev/null | grep -q PONG; then \
			echo "✅ Redis is ready!"; \
			break; \
		fi; \
		echo "⏳ Waiting for Redis... ($$i/30)"; \
		sleep 2; \
	done
	@make migrate
	@make test
	@make test-php

circleci-security: ## Run security scans in CircleCI environment
	@echo "🔒 Running CircleCI security workflow..."
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose -f docker-compose.local.yml build
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose -f docker-compose.local.yml up -d
	@sleep 10
	@echo "Running security scans..."
	@docker-compose -f docker-compose.local.yml exec -T app composer audit
	@docker-compose -f docker-compose.local.yml exec -T app npm audit --audit-level moderate

circleci-build: ## Build images for CircleCI deployment
	@echo "🏗️  Building images for CircleCI deployment..."
	@export VERSION=$(VERSION) GIT_COMMIT=$(GIT_COMMIT) && \
	docker-compose -f docker-compose.local.yml build
	@echo "✅ Images built successfully for deployment"

# CircleCI Testing Commands
test-circleci: ## Run CircleCI test workflow (quick version)
	@echo "🧪 Running CircleCI test workflow..."
	@./test-circleci-quick.sh

test-circleci-quick: ## Run quick CircleCI tests (requires services to be running)
	@echo "🧪 Running quick CircleCI tests..."
	@./test-circleci-quick.sh

test-circleci-build-push: ## Run build and push tests with current registry
	@echo "🧪 Running build and push tests..."
	@echo "Registry: $(REGISTRY)"
	@./build-and-push.sh $(REGISTRY) $(VERSION)

test-circleci-full: ## Run full CircleCI test workflow (includes environment setup)
	@echo "🧪 Running full CircleCI test workflow..."
	@./test-circleci-local.sh

# Configuration Commands
show-config: ## Show current configuration (registry, version, etc.)
	@echo "📋 Current Configuration"
	@echo "======================="
	@echo "Registry: $(REGISTRY)"
	@echo "Version: $(VERSION)"
	@echo "Git Commit: $(GIT_COMMIT)"
	@echo "Registry Source: $(REGISTRY_SRC)"
	@echo "======================="
