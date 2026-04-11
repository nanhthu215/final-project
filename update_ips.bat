@echo off
echo ===== Updating IPs after AWS Academy restart =====

REM Lay IP moi
for /f %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=app-server-1" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set APP1=%%i

for /f %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=app-server-2" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set APP2=%%i

for /f %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=db-server" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set DB=%%i

echo App Server 1 : %APP1%
echo App Server 2 : %APP2%
echo DB Server    : %DB%

REM Cap nhat GitHub Secrets
gh secret set APP_SERVER_1_IP --body "%APP1%" --repo nanhthu215/final-project
gh secret set APP_SERVER_2_IP --body "%APP2%" --repo nanhthu215/final-project

REM Lay ALB IP
for /f %%i in ('nslookup final-project-alb-920589189.us-east-1.elb.amazonaws.com ^| findstr "Address" ^| findstr /v "10.0.0" ^| findstr /v "127.0.0"') do set ALBIP=%%i

echo.
echo ===== DONE! =====
echo GitHub Secrets da cap nhat tu dong!
echo.
echo Con 2 viec phai lam thu cong:
echo 1. Cap nhat DuckDNS IP = lay tu: nslookup final-project-alb-920589189.us-east-1.elb.amazonaws.com
echo 2. Set AWS credentials trong PowerShell truoc khi chay script nay
echo.
pause