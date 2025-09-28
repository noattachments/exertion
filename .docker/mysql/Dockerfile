FROM mysql:8.0

# Custom configuration
COPY .docker/mysql/my.cnf /etc/mysql/conf.d/custom.cnf

# Copy initialization scripts
COPY .docker/mysql/init-test-db.sql /docker-entrypoint-initdb.d/init-test-db.sql

# Initialize database with secure defaults
RUN echo "#!/bin/bash\n" > /docker-entrypoint-initdb.d/init.sql && \
    chmod +x /docker-entrypoint-initdb.d/init.sql

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD}
