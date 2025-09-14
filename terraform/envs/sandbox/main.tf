terraform {
    required_version = ">=1.2.0"
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = ">= 4.0"
      }
    }
}

provider "aws" {
    region = var.aws_region
}

# Llanelli VPC Module

module "llanelli" {
    source = "../../modules/vpc"
    name = "llanelli"
    cidr = var.llanelli_vpc_cidr
    public_subnets = var.llanelli_public_subnets
    private_subnets = var.llanelli_private_subnets
    management_subnet = var.llanelli_management_subnet
    azs = var.azs
    enable_nat = var.enable_nat
}

module "cardiff" {
    source = "../../modules/vpc"
    name = "cardiff"
    cidr = var.cardiff_vpc_cidr
    public_subnets = var.cardiff_public_subnets
    private_subnets = var.cardiff_private_subnets
    management_subnet = var.cardiff_management_subnet
    azs = var.azs
    enable_nat = var.enable_nat
}

resource "aws_vpc_peering_connection" "llanelli_cardiff" {
    vpc_id = module.llanelli.vpc_id
    peer_vpc_id = module.cardiff.vpc_id
    peer_region = var.aws_region
    auto_accept = true
}