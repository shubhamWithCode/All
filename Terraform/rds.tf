provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "db_instance" {
  engine                   = var.engine_name
  username                 = var.user_name
  password                 = var.pass
  skip_final_snapshot      = var.skip_finalSnapshot
  db_subnet_group_name     = aws_db_subnet_group.db_sub_group.id
  delete_automated_backups = var.delete_automated_backup
  multi_az                 = var.multi_az_deployment
  publicly_accessible      = var.public_access
  vpc_security_group_ids   = [data.aws_security_group.tcw_sg.id]
  instance_class           = var.instance_class
  allocated_storage        = 20

  tags = {
    Name = var.db_name
  }
}

#VARIABLES 

variable "engine_name" {
  description = "Enter the DB engine"
  type        = string
  default     = "mysql"
}


variable "db_name" {
  description = "Enter the name of the database to be created inside DB Instance"
  type        = string
  default     = "tcw"
}
variable "user_name" {
  description = "Enter the username for DB"
  type        = string
  default     = "tcw"
}
variable "pass" {
  description = "Enter the username for DB"
  type        = string
  default     = "TheCloudWorld.2019"
}
variable "multi_az_deployment" {
  description = "Enable or disable multi-az deployment"
  type        = bool
  default     = false
}
variable "public_access" {
  description = "Whether public access needed"
  type        = bool
  default     = false
}
variable "skip_finalSnapshot" {
  type    = bool
  default = true
}
variable "delete_automated_backup" {
  type    = bool
  default = true
}
variable "instance_class" {
  type    = string
  default = "db.t2.micro"
}

# DB subnet group
resource "aws_db_subnet_group" "db_sub_group" {
  name       = "main"
  subnet_ids = data.aws_subnet_ids.available_db_subnet.ids
  tags = {
    Name = "My DB subnet group"
  }
}

#OUTPUT = rds address
output "rds_address" {
  value = aws_db_instance.db_instance.address
}