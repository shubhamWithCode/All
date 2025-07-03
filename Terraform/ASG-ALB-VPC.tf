// 1. security group ALB [ Internet -> ALB]

resource "aws_security_group" "ALB-sg" {
  name        = "ALB-sg"
  description = "Security group for the ALB which allow traffic from internet to ALB"
  vpc_id      = aws_vpc.custom-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "ALB-SG"
  }
}

// Security group for the EC2 which allow traffic from [ALB -> EC2]

resource "aws_security_group" "EC2-sg" {
  name        = "EC2-sg"
  description = "Security group for EC2 which allow traffic from ALB to ec2 group"
  vpc_id      = aws_vpc.custom-vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.ALB-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2-SG"
  }
}

//2. Application load balancer

resource "aws_lb" "Application-lb" {
  name               = "application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB-sg.id]
  subnets            = aws_subnet.public-subnet[*].id
  depends_on         = [aws_internet_gateway.igw-vpc]
}

// ALB target group

resource "aws_lb_target_group" "alb-target-group" {
  name     = "alb-target-group"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom-vpc.id

  health_check {
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = "200-399"
  }

  tags = {
    Name = "alb-target-group"
  }
}

//ALB listener

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.Application-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }
  tags = {
    Name = "alb-listener"
  }
}

//Launch template for ec2 instances for ASG

resource "aws_launch_template" "ec2_launch_template" {
  name          = "web-server-template"
  image_id      = "ami-05ffe3c48a9991133"
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.EC2-sg.id]
  }

  user_data = filebase64("userdata.sh")

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ec2-webserver"
    }
  }
}

// Autoscaling group 

resource "aws_autoscaling_group" "ec2-asg" {
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.public-subnet[*].id
  name                = "webserver-asg"
  target_group_arns   = [aws_lb_target_group.alb-target-group.arn]

  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
  health_check_type = "EC2"
}

output "alb-dns-name" {
  value = aws_lb.Application-lb.dns_name
}