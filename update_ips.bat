@echo off
echo ===== Updating IPs after AWS Academy restart =====

REM Lay public IP moi
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

REM Cap nhat GitHub Secrets voi public IP
gh secret set APP_SERVER_1_IP --body "%APP1_PUBLIC%" --repo nanhthu215/final-project
gh secret set APP_SERVER_2_IP --body "%APP2_PUBLIC%" --repo nanhthu215/final-project
echo [OK] GitHub Secrets updated

REM Cap nhat DuckDNS
echo.
echo ===== ACTION REQUIRED =====
for /f %%i in ('nslookup final-project-alb-920589189.us-east-1.elb.amazonaws.com ^| findstr /v "10.0.0" ^| findstr /v "127.0.0" ^| findstr /v "login" ^| findstr /v "Address:" ^| findstr "."') do set ALB_IP=%%i
echo Cap nhat DuckDNS: https://www.duckdns.org/domains
echo Set IP = (chay: nslookup final-project-alb-920589189.us-east-1.elb.amazonaws.com)

REM Cap nhat Ansible inventory tren App Server 1
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
echo ===== DONE! =====
echo.
echo Checklist sau khi chay script:
echo [x] GitHub Secrets da cap nhat
echo [ ] Cap nhat DuckDNS IP
echo [ ] SSH vao App Server 1: ssh -i final-project-key.pem ubuntu@%APP1_PUBLIC%
echo [ ] Chay: bash /home/ubuntu/restart_swarm.sh
echo [ ] Chay: ansible-playbook -i ~/ansible/inventory.ini ~/ansible/playbook.yml --ssh-extra-args="-o StrictHostKeyChecking=no"
echo.
pause