provider "aws" {
  region = var.region
}

# 2 App Servers cho Tier 3
resource "aws_instance" "app_server" {
  count         = 2
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1
  instance_type = "t2.micro"
  key_name      = "vockey" # Dùng tên key mặc định của Lab
  
  tags = { Name = "app-server-${count.index + 1}" }
}

# 1 DB Server
resource "aws_instance" "db_server" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  key_name      = "vockey"
  
  tags = { Name = "db-server" }
}