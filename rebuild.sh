docker compose down --profile dependencies
if [ ! -f ./.env ]; then
    cp ./.env.example ./.env
fi
docker compose pull --profile dependencies
docker compose up -d --profile dependencies
