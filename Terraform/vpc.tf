provider "aws" {
  region = "ap-south-1"
}

# create custom VPC
resource "aws_vpc" "TIAA-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "TIAA-vpc"
  }
}

resource "aws_subnet" "TIAA-public-subnet-01" {
  vpc_id = aws_vpc.TIAA-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = true             # instances will have public IP
  availability_zone = "ap-south-1a"
  tags = {
    Name = "TIAA-public-subnet-01"
  }
}

resource "aws_subnet" "TIAA-public-subnet-02" {
  vpc_id = aws_vpc.TIAA-vpc.id
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1b"
  tags = {
    Name = "TIAA-public-subnet-02"
  }
}

resource "aws_internet_gateway" "TIAA-igw" {
  vpc_id = aws_vpc.TIAA-vpc.id
  tags = {
    Name = "TIAA-igw"
  }
}

#Route table  ----------> route table is for VPC not a particular subnet
resource "aws_route_table" "TIAA-public-rt" {
  vpc_id = aws_vpc.TIAA-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TIAA-igw.id
  }
  tags = {
    Name = "TIAA-public-rt"
  }

}

#route table associations for both public subnets
resource "aws_route_table_association" "TIAA-rta-public-subnet-01" {
  subnet_id = aws_subnet.TIAA-public-subnet-01.id
  route_table_id = aws_route_table.TIAA-public-rt.id
}

resource "aws_route_table_association" "TIAA-rta-public-subnet-02" {
  subnet_id = aws_subnet.TIAA-public-subnet-02.id
  route_table_id = aws_route_table.TIAA-public-rt.id
}

 # EC2 server with security group

resource "aws_instance" "demo-server" {
  ami = "ami-03f4878755434977f"
  instance_type = "t2.micro"
  key_name = "Key"
  vpc_security_group_ids = [ aws_security_group.demo-sg.id ]
  subnet_id = aws_subnet.TIAA-public-subnet-01.id

  for_each = toset(["Jenkins-master" , "build-slave" , "ansible"])  //create 3 instances

  tags = {
    Name = "${each.key}"
  }
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "Allow access -ssh 22"
  vpc_id = aws_vpc.TIAA-vpc.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "jenkins"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-sg"
  }
}

# How to defile modules

module "sgs" {
    source = "../sg_eks"
    vpc_id     =     aws_vpc.TIAA-vpc.id
 }

  module "eks" {
       source = "../eks"
       vpc_id     =     aws_vpc.TIAA-vpc.id
       subnet_ids = [aws_subnet.TIAA-public-subnet-01.id,aws_subnet.TIAA-public-subnet-02.id]
       sg_ids = module.sgs.security_group_public
 }

