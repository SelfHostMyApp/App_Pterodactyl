docker compose --profile dependencies -f docker-compose.yml -p pterodactyl down
docker compose -f docker-compose-network.yml -p pterodactyl-net down
