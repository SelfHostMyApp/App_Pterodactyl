docker compose --profile dependencies -f docker-compose.yml -p pterodactyl down
docker compose -f docker-compose-network.yml -p pterodactyl down
if [ ! -f ./.env ]; then
    cp ./.env.example ./.env
fi
docker compose -f docker-compose-network.yml -p pterodactyl pull
docker compose -f docker-compose-network.yml -p pterodactyl up -d
docker compose --profile dependencies -f docker-compose.yml -p pterodactyl pull
docker compose --profile dependencies -f docker-compose.yml -p pterodactyl up -d
