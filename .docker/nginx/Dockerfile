FROM nginx:1.25-alpine

# Remove default configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom configuration
COPY .docker/nginx/nginx.conf /etc/nginx/conf.d/app.conf

# Create cache directory and ensure proper permissions
RUN mkdir -p /var/cache/nginx /var/run && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/run

# Note: nginx needs to run as root to write to /var/run/nginx.pid
# The nginx process will drop privileges internally

EXPOSE 8080
