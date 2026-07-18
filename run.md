# How to run Polari

See **[README.md](README.md)** — the authoritative build/run/test guide.

Quick prod build (see README §2 for the recommended `pol` path):
```bash
sudo docker compose -f docker-compose.yml -f docker-compose.prod-limits.yml --profile prod up -d --build
```
