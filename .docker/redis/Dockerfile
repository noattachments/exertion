FROM redis:7-alpine

# Copy custom configuration
COPY .docker/redis/redis.conf /usr/local/etc/redis/redis.conf

# Create data directory and set permissions
RUN mkdir -p /data && \
    chown -R redis:redis /data && \
    chmod -R 755 /data

# Run as non-root
RUN mkdir -p /data && chown redis:redis /data
USER redis

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD redis-cli ping | grep -q PONG

CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
