@echo off
echo ===== Updating IPs after AWS Academy restart =====

REM ===================================================================
REM Bước 1: Lấy Public IP mới của các instance từ AWS bằng AWS CLI
REM - Lệnh 'for /f %%i in ('command') do set VAR=%%i' dùng để chạy một lệnh
REM   và lưu kết quả trả về của nó vào biến VAR trong script BAT.
REM - 'aws ec2 describe-instances' lọc instance theo Tag Name và trạng thái chạy
REM - '--query' và '--output text' để chỉ trích xuất duy nhất chuỗi địa chỉ IP.
REM ===================================================================
for /f %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=app-server-1" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set APP1_PUBLIC=%%i

for /f %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=app-server-2" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set APP2_PUBLIC=%%i

for /f %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=db-server" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set DB_PUBLIC=%%i

echo App Server 1 (public) : %APP1_PUBLIC%
echo App Server 2 (public) : %APP2_PUBLIC%
echo DB Server    (public) : %DB_PUBLIC%
echo Private IPs khong thay doi:
echo   App Server 1 private: 172.31.36.207
echo   App Server 2 private: 172.31.35.211
echo   DB Server    private: 172.31.33.108

REM ===================================================================
REM Bước 2: Cập nhật GitHub Secrets bằng GitHub CLI (gh)
REM - Lệnh 'gh secret set' sẽ tự cập nhật biến secret nằm trên kho lưu trữ
REM - Việc này rất quan trọng để luồng CI/CD (GitHub Actions) có thể SSH vào đúng IP mới
REM ===================================================================
gh secret set APP_SERVER_1_IP --body "%APP1_PUBLIC%" --repo nanhthu215/final-project
gh secret set APP_SERVER_2_IP --body "%APP2_PUBLIC%" --repo nanhthu215/final-project
echo [OK] GitHub Secrets updated


REM ===================================================================
REM Bước 3: In ra màn hình các dòng lệnh copy-paste cho việc thiết lập Inventory Ansible
REM Lưu ý: Các lệnh từ echo cat ^> tới EOF chỉ in ra màn hình chứ KHÔNG chạy trên Windows.
REM Nó đang render ra một chuỗi lệnh HereDoc (<< EOF) của Linux. 
REM Ý đồ là bạn sẽ copy nguyên cụm này rồi dán vào Terminal của máy ảo Linux (App Server 1)
REM để nó tự động tạo file inventory.ini với nội dung ở giữa cụm EOF.
REM ===================================================================
echo.
echo ===== Cap nhat Ansible inventory tren server =====
echo Chay lenh nay tren SSH App Server 1 (%APP1_PUBLIC%):
echo.
echo ssh -i final-project-key.pem ubuntu@%APP1_PUBLIC%
echo.
echo Roi chay:
echo cat ^> ~/ansible/inventory.ini ^<^< 'EOF'
echo [app_servers]
echo app1 ansible_host=172.31.36.207 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/final-project-key.pem
echo app2 ansible_host=172.31.35.211 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/final-project-key.pem
echo [db_servers]
echo db ansible_host=172.31.33.108 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/final-project-key.pem
echo [all:vars]
echo ansible_python_interpreter=/usr/bin/python3
echo EOF
echo.
echo ^^ Copy toan bo tu dong "cat ^>" den dong "EOF" phia tren (gom ca dong EOF)

echo.
echo ===== DONE! =====
echo.
echo Checklist sau khi chay script:
echo [x] GitHub Secrets da cap nhat

echo [ ] SSH vao App Server 1: ssh -i final-project-key.pem ubuntu@%APP1_PUBLIC%
echo [ ] Chay: bash /home/ubuntu/restart_swarm.sh
echo [ ] Chay: ansible-playbook -i ~/ansible/inventory.ini ~/ansible/playbook.yml --ssh-extra-args="-o StrictHostKeyChecking=no"
echo.
pause