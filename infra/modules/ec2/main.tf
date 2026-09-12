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
  description = "No inbound; allow all outbound for SSM"
  vpc_id      = var.vpc_id

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
  instance_type          = var.instnace_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = var.instance_profile_name

  # Install Docker so it's ready for Phase 2
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOF

  tags = { Name = "${var.name}-app" }
}
