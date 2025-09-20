FROM nginx:1.25-alpine

# Remove default configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom configuration
COPY .docker/nginx/nginx.conf /etc/nginx/conf.d/app.conf

# Create cache directory
RUN mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx

# Switch to non-root user
USER nginx

EXPOSE 8080
