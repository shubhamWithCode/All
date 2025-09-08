// 1️⃣ Security Group for ALB (Internet → ALB)
resource "aws_security_group" "ALB-sg" {
  name        = "ALB-sg"
  description = "Allow HTTP traffic from internet to ALB"
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

// 2️⃣ Security Group for EC2 (ALB → EC2)
resource "aws_security_group" "EC2-sg" {
  name        = "EC2-sg"
  description = "Allow traffic from ALB to EC2"
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

// 3️⃣ Application Load Balancer
resource "aws_lb" "Application-lb" {
  name               = "application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB-sg.id]
  subnets            = aws_subnet.public-subnet[*].id
  depends_on         = [aws_internet_gateway.igw-vpc]
}

// 4️⃣ ALB Target Group
resource "aws_lb_target_group" "alb-target-group" {
  name     = "alb-target-group"
  port     = 80
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

// 5️⃣ ALB Listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.Application-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }

  tags = {
    Name = "alb-listener"
  }
}

// 6️⃣ Launch Template for EC2 Instances
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

// 7️⃣ Auto Scaling Group
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

// 8️⃣ Auto Scaling Policy (Scale Out)
resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2-asg.name
}

// 9️⃣ CloudWatch Metric Alarm (CPU Utilization)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2-asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out_policy.arn]
}

// 🔟 Output ALB DNS Name
output "alb-dns-name" {
  value = aws_lb.Application-lb.dns_name
}
