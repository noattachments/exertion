# --- Builder stage ---
FROM php:8.3-fpm-alpine AS builder

# Set working directory
WORKDIR /app

# Install system dependencies, PHP build deps, Node.js and npm
RUN apk add --no-cache \
        bash curl git nodejs npm \
        libzip-dev libpng-dev libjpeg-turbo-dev freetype-dev \
        oniguruma-dev icu-dev zlib-dev libxml2-dev postgresql-dev build-base autoconf make g++ \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install -j$(nproc) \
        pdo_mysql pdo_pgsql zip gd mbstring intl opcache exif pcntl xml

# Install and enable Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Configure PHP
COPY .docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy composer files first
COPY composer.* /app/

# Copy minimal required files for composer install
COPY artisan /app/artisan
COPY bootstrap/app.php /app/bootstrap/app.php
COPY config/ /app/config/
COPY routes/ /app/routes/
COPY app/ /app/app/

# Ensure bootstrap/cache exists and is writable
RUN mkdir -p bootstrap/cache \
    && chmod -R 775 bootstrap/cache

# Install PHP dependencies (no dev) - skip scripts that require full app
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts

# Copy the rest of the application + assets
COPY . /app

# Run composer scripts after all files are in place
RUN composer run-script post-autoload-dump

# Install Node dependencies
RUN npm ci --omit=dev

# Use build-specific Vite config (without wayfinder)
RUN cp vite.config.build.ts vite.config.ts

# Build frontend assets
RUN npm run build

# --- Production stage ---
FROM php:8.3-fpm-alpine AS production

#
WORKDIR /var/www/html

# Install runtime dependencies and minimal build tools for PECL
RUN apk add --no-cache \
    libzip libzip-dev libpng libpng-dev libjpeg-turbo libjpeg-turbo-dev freetype freetype-dev \
    oniguruma oniguruma-dev icu icu-dev zlib zlib-dev libxml2 libxml2-dev \
    autoconf make gcc musl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql zip gd mbstring intl opcache exif pcntl xml \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf make gcc musl-dev

# Create non-root user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -s /bin/sh -D app

# Copy application files with correct ownership from builder
COPY --from=builder --chown=app:app /app/vendor ./vendor
COPY --from=builder --chown=app:app /app/public ./public
COPY --from=builder --chown=app:app /app/bootstrap ./bootstrap
COPY --from=builder --chown=app:app /app/config ./config
COPY --from=builder --chown=app:app /app/routes ./routes
COPY --from=builder --chown=app:app /app/app ./app
COPY --from=builder --chown=app:app /app/database ./database
COPY --from=builder --chown=app:app /app/resources/views ./resources/views
COPY --from=builder --chown=app:app /app/artisan ./artisan

# Create storage directory and set proper permissions
RUN mkdir -p storage/logs \
    && chmod -R 755 bootstrap \
    && chmod -R 775 bootstrap/cache \
    && chmod -R 755 storage \
    && chmod -R 775 storage/logs

# Switch to non-root user
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php-fpm-healthcheck

EXPOSE 9000
