########################################
# VPC + Subnets (2 public for ALB, 1 private for EC2)
########################################
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_public_a
  availability_zone       = var.az_a
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_public_b
  availability_zone       = var.az_b
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-b" }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_private_a
  availability_zone       = var.az_a
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.project_name}-private-a" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-rtb-public" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# --- Private route table for the private subnet ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-rtb-private" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# --- S3 Gateway Endpoint (for AL2/YUM repos on S3) ---
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = { Name = "${var.project_name}-vpce-s3" }
}


########################################
# Security Groups
########################################
# ALB: allow HTTP from anywhere; egress anywhere
resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
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

  tags = { Name = "${var.project_name}-alb-sg" }
}

# EC2: allow HTTP only from ALB SG; no SSH; egress to VPC endpoints
resource "aws_security_group" "ec2_sg" {
  name   = "${var.project_name}-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # egress wide open is fine; we'll rely on private subnet + no public IP
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ec2-sg" }
}

########################################
# VPC Endpoints for SSM (no NAT needed)
########################################
# Endpoints use HTTPS (443) within the VPC; attach an SG that allows 443 from instances
resource "aws_security_group" "vpce_sg" {
  name   = "${var.project_name}-vpce-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-vpce-sg" }
}

# Interface endpoints in the private subnet (can put in multiple subnets for HA)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-vpce-ssm" }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-vpce-ec2messages" }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-vpce-ssmmessages" }
}

########################################
# IAM for EC2 (SSM access + Patch)
########################################
data "aws_iam_policy" "ssm_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "ssm_patch" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.aws_iam_policy.ssm_core.arn
}

resource "aws_iam_role_policy_attachment" "attach_ssm_patch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.aws_iam_policy.ssm_patch.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

########################################
# EC2 Instance (private; no public IP)
########################################
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  tags = {
    Name       = "${var.project_name}-web"
    PatchGroup = "Linux-Prod"
  }
}

########################################
# User data or SSM association to install nginx
########################################
resource "aws_ssm_document" "install_nginx" {
  name          = "${var.project_name}-install-nginx"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Install and start nginx",
    mainSteps = [{
      action = "aws:runShellScript",
      name   = "installNginx",
      inputs = {
        runCommand = [
          "sudo yum -y install nginx || sudo amazon-linux-extras install -y nginx1",
          "sudo systemctl enable nginx",
          "sudo systemctl start nginx",
          "echo 'Hello via ALB (private EC2, SSM-managed).' | sudo tee /usr/share/nginx/html/index.html"
        ]
      }
    }]
  })
}

resource "aws_ssm_association" "install_nginx_once" {
  name             = aws_ssm_document.install_nginx.name
  association_name = "${var.project_name}-install-nginx-once"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.web.id]
  }
}


########################################
# Application Load Balancer + Target Group
########################################
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  idle_timeout       = 60
  tags               = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  tags = { Name = "${var.project_name}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

########################################
# Patch Manager: daily scan
########################################
resource "aws_ssm_association" "daily_patch_scan" {
  name                = "AWS-RunPatchBaseline"
  association_name    = "${var.project_name}-patch-scan-daily"
  schedule_expression = "cron(0 3 * * ? *)" # 03:00 UTC daily

  targets {
    key    = "tag:PatchGroup"
    values = ["Linux-Prod"]
  }

  # Inspector/provider v5 expects string values here
  parameters = {
    Operation = "Scan"
  }
}


########################################
# Amazon Inspector v2 (enable via CLI after apply)
########################################
# aws inspector2 enable --resource-types EC2 --region ${var.region}
