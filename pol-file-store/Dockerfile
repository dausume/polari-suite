FROM minio/minio:latest

# MinIO data directory
VOLUME /data

# API port: 9000, Console port: 9001
EXPOSE 9000 9001

# Start MinIO server with console enabled
# Bucket initialization is handled by the Spring Boot application
# via MinioDatasourceInitializer / LegislationBucketInitializer
CMD ["server", "/data", "--console-address", ":9001"]
