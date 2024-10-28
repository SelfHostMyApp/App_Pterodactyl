docker compose --profile dependencies down
if [ ! -f ./.env ]; then
    cp ./.env.example ./.env
fi
docker compose --profile dependencies pull
docker compose --profile dependencies up -d
