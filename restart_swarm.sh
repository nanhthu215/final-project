  #!/bin/bash
  echo "===== Restarting Swarm services & Rejoining Nodes ====="

  # 1. Dọn dẹp container rác để tránh trùng cổng
  docker stop node-exporter cadvisor 2>/dev/null || true
  docker rm node-exporter cadvisor 2>/dev/null || true

  # 1.0 Dọn image cũ để tránh đầy disk (tích lũy sau nhiều lần deploy)
  # Mỗi lần CI/CD push image SHA mới là một layer được lưu xuống disk
  # docker image prune -f chỉ xóa dangling images (không có tag nào trỏ đến)
  echo "--- Dọn image cũ không dùng ---"
  docker image prune -f
  echo "[OK] Đã dọn image cũ"

  # 1.1 Tạo file cấu hình Prometheus tự động
  mkdir -p /home/ubuntu/monitoring
  cat <<EOF > /home/ubuntu/monitoring/prometheus.yml
  global:
    scrape_interval: 15s
    evaluation_interval: 15s

  scrape_configs:
    - job_name: 'prometheus'
      static_configs:
        - targets: ['localhost:9090']

    - job_name: 'node-exporter'
      static_configs:
        - targets:
            - '172.31.36.207:9100'  # App Server 1
            - '172.31.35.211:9100'  # App Server 2
            - '172.31.33.108:9100'  # DB Server

    - job_name: 'cadvisor'
      static_configs:
        - targets:
            - '172.31.36.207:8080'  # App Server 1
            - '172.31.35.211:8080'  # App Server 2
  EOF
  echo "[OK] Đã tạo file prometheus.yml tự động"

  # 2. Lấy chìa khóa (Join Token) mới từ máy Manager
  # Token này giống như vé mời vào cụm Swarm (dành cho node thợ - Worker)
  JOIN_TOKEN=$(docker swarm join-token worker -q)
  echo "Mã gia nhập mới: $JOIN_TOKEN"

  # 3. Ép máy 2 thoát cụm cũ ra và gia nhập lại cụm mới (Dùng IP Private)
  # - ssh -i: Đăng nhập vào App Server 2 không cần mật khẩu
  # - docker swarm leave --force: Rời cụm Swarm cũ nếu bị lỗi
  # - docker swarm join --token: Lấy vé mời ở bước 2 cắm vào để báo cáo lên máy Manager
  ssh -i /home/ubuntu/final-project-key.pem \
      -o StrictHostKeyChecking=no \
      ubuntu@172.31.35.211 \
      "docker swarm leave --force 2>/dev/null; docker swarm join --token $JOIN_TOKEN 172.31.36.207:2377"

  echo "Máy 2 đã gia nhập lại thành công!"
  sleep 5

  # 3.5 Dọn dẹp các node cũ bị Down (tích lũy từ các lần restart trước)
  # Nguyên nhân: mỗi lần Worker leave→rejoin, entry cũ vẫn còn trong cluster list
  # với status=Down → global services tạo thừa task
  echo "--- Dọn dẹp node Down cũ ---"
  docker node ls | grep "Down" | awk '{print $1}' | xargs -r docker node rm 2>/dev/null || true
  echo "[OK] Đã xóa node Down cũ — cluster đã sạch"

  # 4. Triển khai lại toàn bộ hệ thống (Stack)
  # Lệnh docker stack deploy sẽ đọc file docker-stack.yml để tạo các service, replica, networking...
  docker stack deploy -c /home/ubuntu/docker-stack.yml myapp
  sleep 20

  # 5. Cập nhật App để ép nó kết nối lại DB
  docker service update --force myapp_web
  sleep 15

  # 6. Kiểm tra thành quả
  echo "--- Trạng thái các máy ---"
  docker node ls
  echo "--- Trạng thái dịch vụ ---"
  docker service ls
  echo "--- Kiểm tra kết nối Database ---"
  curl http://localhost:3000/health
  echo "===== DONE! ====="