provider "aws" {
  region = var.region
}

locals {
  logs_name   = "log-${basename(path.cwd)}"
  ec2_name = "bastion"
  alb_name = "nlb-mod4"
  tags = {
    vpc    = local.logs_name
  }
  s3_bucket_name = lower("vpc-flow-logs-to-s3-${random_string.suffix.result}")
# Se tienen que actualizar los SO para que funcione SSM
  ubuntu_user_data = <<-EOT
  #!/bin/bash -xe
  apt update && apt install python3-virtualenv git nano curl -y
  EOT
  amz2_user_data = <<-EOT
  #!/bin/bash -xe
  yum update -y && yum install -y nano curl 
  EOT
}

resource "random_string" "suffix" {
  length           = 6
  special          = false
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"
  name = "mod4"
  cidr = "10.0.0.0/24"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.0.0/26", "10.0.0.64/26" ]
  public_subnets  = ["10.0.0.128/26", "10.0.0.192/26"]
  #enable_nat_gateway                   = true
  #single_nat_gateway                   = true
  enable_dns_hostnames                 = true
  enable_flow_log                      = true
  flow_log_destination_type = "s3"
  flow_log_destination_arn  = module.s3_bucket.s3_bucket_arn
}


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.202*-x86_64-ebs"]
  }
}

module "ssm_instance_profile" {
  source  = "bayupw/ssm-instance-profile/aws"
  version = "1.1.0"
}

module "custom_ami" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"
  name = "custom_ami"
  count = 1
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data = filebase64("${path.module}/install.sh")
  iam_instance_profile = module.ssm_instance_profile.aws_iam_instance_profile
  tags = {
    Name   = "custom-${count.index}"
    Owner  = "loliva"
  }
}

resource "aws_ami_from_instance" "custom" {
  name               = "4launch-template"
  source_instance_id = module.custom_ami[0].id
  snapshot_without_reboot = true
}