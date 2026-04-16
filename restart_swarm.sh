#!/bin/bash
echo "===== Restarting Swarm services & Rejoining Nodes ====="

# 1. Dọn dẹp container rác để tránh trùng cổng
docker stop node-exporter cadvisor 2>/dev/null || true
docker rm node-exporter cadvisor 2>/dev/null || true

# 2. Lấy chìa khóa (Join Token) mới từ Manager
JOIN_TOKEN=$(docker swarm join-token worker -q)
echo "Mã gia nhập mới: $JOIN_TOKEN"

# 3. Ép máy 2 thoát ra và gia nhập lại (Dùng IP Private)
# Lưu ý: Thư phải có file final-project-key.pem ở /home/ubuntu/ nhé
ssh -i /home/ubuntu/final-project-key.pem \
    -o StrictHostKeyChecking=no \
    ubuntu@172.31.35.211 \
    "docker swarm leave --force 2>/dev/null; docker swarm join --token $JOIN_TOKEN 172.31.36.207:2377"

echo "Máy 2 đã gia nhập lại thành công!"
sleep 5

# 4. Triển khai lại toàn bộ hệ thống (Stack)
docker stack deploy -c /home/ubuntu/docker-stack.yml myapp
sleep 20

# 5. Cập nhật App để ép nó kết nối lại DB
docker service update --force myapp_web
sleep 15

# 6. Kiểm tra thành quả
echo "--- Trạng thái các máy (Phải hiện Ready) ---"
docker node ls
echo "--- Trạng thái dịch vụ (Phải hiện 2/2) ---"
docker service ls
echo "--- Kiểm tra kết nối Database ---"
curl http://localhost:3000/health
echo "===== HOÀN THÀNH! CHIẾN THẮNG RỒI THƯ ƠI! ====="