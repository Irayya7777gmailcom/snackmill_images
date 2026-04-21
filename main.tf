# Fixes the EC2 configuration by removing reliance on pre-existing VPC/subnet/SG and instead creating the required networking dependencies (VPC, subnet, IGW, route table, SG) so the instance can be launched without default-VPC assumptions. Note: the reported 'Terraform CLI not found' is an environment issue and cannot be fixed via Terraform code.
# Generated Terraform code for AWS in us-east-1

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.25.0"
    }
  }
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instance (e.g., ami-xxxxxxxxxxxxxxxxx)."
  type        = string

  validation {
    condition     = can(regex("^ami-[a-z0-9]{17}$", var.ami_id))
    error_message = "ami_id must match the pattern ami-[a-z0-9]{17}."
  }
}

variable "availability_zone" {
  description = "Availability Zone to place the instance in (e.g., us-east-1a)."
  type        = string

  validation {
    condition     = length(var.availability_zone) > 0
    error_message = "availability_zone must be a non-empty string."
  }
}

variable "instance_type" {
  description = "EC2 instance type (e.g., t3.micro)."
  type        = string

  validation {
    condition     = length(var.instance_type) > 0
    error_message = "instance_type must be a non-empty string."
  }
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair to enable SSH access."
  type        = string

  validation {
    condition     = length(var.key_name) > 0
    error_message = "key_name must be a non-empty string."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC that will contain the instance."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet that will contain the instance."
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_ingress_cidr" {
  description = "CIDR block allowed to SSH to the instance (port 22)."
  type        = string
  default     = "0.0.0.0/0"
}

provider "aws" {
  {{block_to_replace_cred}}
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "main" {
  availability_zone = var.availability_zone
  cidr_block        = var.subnet_cidr
  vpc_id            = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.main.id
}

resource "aws_security_group" "main" {
  description = "Security group for EC2 instance"
  name_prefix = "ec2-"
  vpc_id      = aws_vpc.main.id

  ingress {
    cidr_blocks = [var.ssh_ingress_cidr]
    description = "SSH"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_instance" "main" {
  ami               = var.ami_id
  availability_zone = var.availability_zone
  instance_type     = var.instance_type
  key_name          = var.key_name
  subnet_id         = aws_subnet.main.id

  vpc_security_group_ids = [aws_security_group.main.id]
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance."
  value       = aws_instance.main.arn
}

output "availability_zone" {
  description = "Availability Zone where the instance is placed."
  value       = aws_instance.main.availability_zone
}

output "public_ip" {
  description = "Public IP address assigned to the instance (if any)."
  value       = aws_instance.main.public_ip
}

output "private_ip" {
  description = "Private IP address assigned to the instance."
  value       = aws_instance.main.private_ip
}

output "vpc_id" {
  description = "ID of the VPC created for the instance."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the subnet created for the instance."
  value       = aws_subnet.main.id
}

output "security_group_id" {
  description = "ID of the security group associated with the instance."
  value       = aws_security_group.main.id
}