docker compose down
if [ ! -f ./.env ]; then
    cp ./.env.example ./.env
fi
docker compose pull --profile dependencies
docker compose up -d --profile dependencies
