# Final Project — Startup Guide After AWS Academy Restart

> **Áp dụng mỗi lần**: AWS Academy hết phiên hoặc EC2 bị restart → Public IP thay đổi.  
> Thực hiện đúng thứ tự: **Bước 1 → 2 → 3 → 4**.

---

## Yêu cầu trước khi bắt đầu

| Công cụ | Mục đích | Kiểm tra |
|---|---|---|
| AWS CLI | Lấy Public IP mới từ EC2 | `aws --version` |
| GitHub CLI (`gh`) | Cập nhật GitHub Secrets | `gh auth status` |
| PEM key | SSH vào servers | File `final-project-key.pem` trong thư mục project |

---

## Bước 1 — Chạy `update_ips.bat` (trên máy Windows)

> Script này tự động lấy Public IP mới từ AWS và cập nhật vào GitHub Secrets.

```bat
.\update_ips.bat
```

**Script làm 3 việc:**
1. Dùng AWS CLI lấy Public IP mới của 3 server (`app-server-1`, `app-server-2`, `db-server`)
2. Cập nhật 2 GitHub Secrets (`APP_SERVER_1_IP`, `APP_SERVER_2_IP`) — để CI/CD pipeline SSH đúng server
3. In ra màn hình lệnh SSH và các lệnh cần chạy tiếp theo

**Kết quả kỳ vọng:**
```
===== Updating IPs after AWS Academy restart =====
App Server 1 (public) : <IP_MOI_1>
App Server 2 (public) : <IP_MOI_2>
DB Server    (public) : <IP_MOI_3>
[OK] GitHub Secrets updated
```

> ⚠️ **Nếu lệnh AWS CLI báo lỗi**: Vào AWS Academy → Start Lab → chờ lab ready → thử lại.

---

## Bước 2 — SSH vào App Server 1

> App Server 1 là **Swarm Manager** — tất cả lệnh quản lý cluster đều chạy ở đây.

Lấy IP từ output của Bước 1, sau đó SSH:

```bash
ssh -i final-project-key.pem ubuntu@<APP_SERVER_1_PUBLIC_IP>
```

**Ví dụ:**
```bash
ssh -i final-project-key.pem ubuntu@54.89.236.238
```

> 💡 IP public thay đổi mỗi lần restart. Luôn lấy IP từ output Bước 1.

---

## Bước 3 — Chạy `restart_swarm.sh` (trên App Server 1)

> Script này khởi động lại toàn bộ cụm Docker Swarm và deploy stack.

```bash
bash /home/ubuntu/restart_swarm.sh
```

**Script làm 6 việc theo thứ tự:**

| # | Hành động | Mục đích |
|---|---|---|
| 1 | Dọn dẹp container cũ (`node-exporter`, `cadvisor`) | Tránh conflict port khi deploy lại |
| 1.1 | Tạo lại `/home/ubuntu/monitoring/prometheus.yml` | Đảm bảo Prometheus có config đúng sau restart |
| 2 | Lấy Worker Join Token mới từ Manager | Token thay đổi sau mỗi lần Swarm restart |
| 3 | SSH vào App Server 2, force leave → rejoin Swarm | Worker cần gia nhập lại cluster với token mới |
| 4 | `docker stack deploy -c /home/ubuntu/docker-stack.yml myapp` | Deploy toàn bộ stack (web, prometheus, grafana, node-exporter, cadvisor) |
| 5 | `docker service update --force myapp_web` | Ép web service kết nối lại MongoDB sau restart |
| 6 | Kiểm tra `docker node ls` + `docker service ls` + `curl /health` | Xác nhận cluster và ứng dụng healthy |

**Kết quả kỳ vọng:**
```
Máy 2 đã gia nhập lại thành công!
[Stack deployed]
--- Trạng thái các máy (Phải hiện Ready) ---
ID    HOSTNAME              STATUS    AVAILABILITY
xxx   ip-172-31-36-207 *   Ready     Active        Leader
yyy   ip-172-31-35-211     Ready     Active
--- Trạng thái dịch vụ (Phải hiện 2/2) ---
myapp_web       replicated   2/2
myapp_prometheus replicated  1/1
myapp_grafana   replicated   1/1
--- Kiểm tra kết nối Database ---
{"status":"ok","dataSource":"mongodb",...}
===== DONE! =====
```

> ⚠️ **Nếu `docker service ls` không hiện 2/2**: Đợi thêm 30 giây rồi chạy `docker service ps myapp_web` để xem chi tiết.

---

## Bước 4 — Chạy Ansible Playbook (trên App Server 1)

> Ansible cấu hình lại Nginx, DuckDNS, Prometheus trên cả 3 server — đảm bảo idempotent.

```bash
ansible-playbook -i ~/ansible/inventory.ini ~/ansible/playbook.yml \
  --ssh-extra-args="-o StrictHostKeyChecking=no"
```

**Playbook làm gì trên từng server:**

**App Server 1 + App Server 2** (`app_servers`):
- Cài Docker, Nginx, Certbot (idempotent — bỏ qua nếu đã có)
- Cấu hình Nginx reverse proxy: `localhost:80` → `localhost:3000`
- Tạo script `/home/ubuntu/update-duckdns.sh` và cài crontab `@reboot` — tự cập nhật IP vào DuckDNS khi server khởi động lại

**DB Server** (`db_servers`):
- Cài Docker
- Ghi lại file `prometheus.yml` với đúng Private IP của 3 server
- Restart container Prometheus để load config mới

**Kết quả kỳ vọng:**
```
PLAY RECAP
app1   : ok=9  changed=0  unreachable=0  failed=0
app2   : ok=9  changed=0  unreachable=0  failed=0
db     : ok=9  changed=0  unreachable=0  failed=0
```

> 💡 `changed=0` là tốt — nghĩa là cấu hình đã đúng, Ansible không cần sửa gì thêm.

---

## Kiểm tra sau khi hoàn thành

```bash
# Trên App Server 1 — kiểm tra cluster
docker node ls
docker service ls

# Kiểm tra ứng dụng
curl http://localhost:3000/health

# Kiểm tra Nginx + HTTPS (từ browser)
# https://finalprojectdeloy.duckdns.org
```

---

## Checklist nhanh

```
[ ] Bước 1: .\update_ips.bat → GitHub Secrets updated ✅
[ ] Bước 2: SSH vào App Server 1
[ ] Bước 3: bash /home/ubuntu/restart_swarm.sh → DONE ✅
[ ] Bước 4: ansible-playbook ... → RECAP failed=0 ✅
[ ] Verify: curl /health → {"status":"ok"} ✅
[ ] Verify: https://finalprojectdeloy.duckdns.org → 🔒 HTTPS OK ✅
```

---

## Thông tin hạ tầng

| Server | Role | Private IP | Public IP |
|---|---|---|---|
| App Server 1 | Swarm Manager | `172.31.36.207` | Thay đổi mỗi restart |
| App Server 2 | Swarm Worker | `172.31.35.211` | Thay đổi mỗi restart |
| DB Server | MongoDB + Prometheus + Grafana | `172.31.33.108` | Thay đổi mỗi restart |

> **Private IP luôn cố định** — dùng Private IP cho mọi kết nối nội bộ (Swarm, MongoDB, Prometheus scrape targets).
