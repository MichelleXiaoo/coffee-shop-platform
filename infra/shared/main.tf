terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "michelle-coffee-shop-001"
    key          = "shared/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

resource "aws_ecr_repository" "app" {
  name = "coffee-shop"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Project = "coffee-shop" }
}

# keep storage and cost bounded --> expire all but 10 newest images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description   = "Keep only the 10 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}

variable "github_repo" {
  type = string
  description = "GitHub repo in owner/name form"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  
  # GitHub's published CA thumbprints (both current values).
  # Hardcoded deliberately: deriving these from the TLS chain picked the leaf
  # certificate instead of the CA, which broke token validation.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

# Only THIS repo, and only the main branch, may assume the role
data "aws_iam_policy_document" "gha_assume" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = ["sts.amazonaws.com"]
    }

    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }    
  }
}

data "aws_iam_policy_document" "gha_permissions" {
  statement {
    sid = "EcrAuthToken"
    effect = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]      # this actin doesn't support resource scoping
  }

  statement {
    sid = "EcrPushPull"
    effect = "Allow"
    actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
    ]
    resources = [aws_ecr_repository.app.arn]    # scoped to this repo only
  }

  statement {
    sid = "FindTargetInstances"
    effect = "Allow"
    actions = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  statement {
    sid = "DeployViaSSM"
    effect = "Allow"
    actions = [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ssm:ListCommandInvocations",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "github_actions" {
  name = "coffee-shop-github-actions"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
}

resource "aws_iam_role_policy" "github_actions" {
  name = "coffee-shop-pipeline"
  role = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.gha_permissions.json
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

resource "aws_iam_user" "ci" {
  name = "coffee-shop-ci"
}

resource "aws_iam_user_policy" "ci" {
  name = "coffee-shop-pipeline"
  user = aws_iam_user.ci.name
  policy = data.aws_iam_policy_document.gha_permissions.json
}
