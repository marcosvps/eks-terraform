provider "aws" {
    region = "us-east-2"
}

module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    name    = "marcos-porto-eks-vpc"
    cidr    = "172.16.0.0/16"
    azs     = ["us-east-2a", "us-east-2b", "us-east-2c"]
    private_subnets = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
    public_subnets  = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
    enable_nat_gateway = true
    single_nat_gateway  = true
    one_nat_gateway_per_az = false
    tags = {
        Terraform = "true"
        Environment = "dev"
    }
}

module "eks" {
    
    source          = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"

    cluster_name    = "marcos-porto-eks-cluster"
    cluster_version = "1.31"
    
    cluster_endpoint_public_access  = true
    enable_cluster_creator_admin_permissions = true

    vpc_id          = module.vpc.vpc_id
    subnet_ids         = module.vpc.private_subnets
    

    eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2_x86_64"
      instance_types = ["t3.medium"]

      min_size = 1
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2
      capacity_type = "SPOT"
    }
  }

    tags = {
        Terraform = "true"
        Environment = "dev"
    }
}


