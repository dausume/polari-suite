
# Production Build
sudo docker compose -f docker-compose.yml -f docker-compose.prod-limits.yml --profile prod up -d --build