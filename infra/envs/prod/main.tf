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
    key          = "envs/prod/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source   = "../../modules/vpc"
  name     = var.env_name
  vpc_cidr = var.vap_cidr
}

module "iam" {
  source = "../../modules/iam"
  name   = var.env_name
}

module "ec2" {
  source                = "../../modules/ec2"
  name                  = var.env_name
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.public_subnet_ids[0]
  instance_profile_name = module.iam.instance_profile_name
  instnace_type         = var.instance_type
  # allowed_http_cidrs    = ["${chomp(data.http.my_ip.response_body)}/32"]
  # No allowed_http_cidrs --> module default [] --> zero inbound to prod
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "ec2_instance_id" {
  value = module.ec2.instance_id
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

