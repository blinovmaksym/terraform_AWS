provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "mondyk8awsklas"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name                 = "k8s-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name    = "${local.cluster_name}"
  cluster_version = "1.24"

  vpc_id = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  cluster_endpoint_public_access  = true

  create_kms_key            = false
  cluster_encryption_config = {}





  
  eks_managed_node_groups = {
    main = {
      min_size     = 2
      max_size     = 10
      desired_size = 2

      instance_types = ["t3.medium"]
      ami_id = "ami-09e35c383eea7b5ec"
      capacity_type  = "SPOT"
    }
  }

}
resource "aws_route53_zone" "dns" {
  name     = "it-sproutdevteam.fun"
}

