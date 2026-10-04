# Always get the latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# SG: NO inbound at all; allow outbound (SSM -> 443)
resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Inbound only if allowed_http_cidrs set. All outbound for SSM"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.allowed_http_cidrs) > 0 ? [1] : []
    content {
      description = "HTTP from allowed CIDRs"
      from_port = var.app_port
      to_port = var.app_port
      protocol = "tcp"
      cidr_blocks = var.allowed_http_cidrs
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-sg" }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = var.instance_profile_name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    enable_monitoring      = var.enable_monitoring
    grafana_admin_password = var.grafana_admin_password
  })

  tags = { Name = "${var.name}-app" }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"    #IMDSv2 only
    http_put_response_hop_limit = 2   # Allow containers to reach IMDS 
  }
}
