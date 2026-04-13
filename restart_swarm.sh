#!/bin/bash
# Chay tren App Server 1 sau khi restart AWS Academy lab
echo "===== Restarting Swarm services ====="

# Force update de Swarm reconnect MongoDB
docker service update --force myapp_web
sleep 15

# Verify
docker service ps myapp_web
curl http://localhost:3000/health
echo "===== Done! ====="