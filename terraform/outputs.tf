output "app_server_ips" {
  value = aws_instance.app_server[*].public_ip
}

output "db_server_ip" {
  value = aws_instance.db_server.public_ip
}