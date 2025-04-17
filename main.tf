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
    
    public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = "marcos-porto-eks-cluster"
  }
}

module "eks" {
    
    source          = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"

    cluster_name    = "marcos-porto-eks-cluster"
    cluster_version = "1.31"
    
    cluster_addons = {
        #aws-ebs-csi-driver      = { most_recent = true }
        coredns                 = {
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
        #eks-pod-identity-agent  = { most_recent = true }
        kube-proxy              = { most_recent = true }
    }
    
    cluster_endpoint_public_access  = true
    enable_cluster_creator_admin_permissions = true

    vpc_id              = module.vpc.vpc_id
    subnet_ids          = module.vpc.private_subnets
    

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
    
    karpenter = {
      ami_type       = "AL2_x86_64"
      instance_types = ["m5.large"]

      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }

      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

    node_security_group_tags = {
        "Terraform" = "true",
        "Environment" = "dev",
        # NOTE - if creating multiple security groups with this module, only tag the
        # security group that Karpenter should utilize with the following tag
        # (i.e. - at most, only one security group should have this tag in your account)
        "karpenter.sh/discovery" = "marcos-porto-eks-cluster"
    }

    tags = {
        Terraform = "true"
        Environment = "dev"
    }
}


