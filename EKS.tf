data "aws_eks_cluster" "cluster" {
    name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
    name = module.eks.cluster_id
}

provider "kubernetes" {
    host                      = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate    = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                     = data.aws_eks_cluster.auth.cluster.token
    load_config_file          = false
    version                   = "~> 1.11"
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "jerry-edgar"
}

module "vpc" {
    source               = "terraform-aws-modules/vpc/aws"
    version              = "2.58.0"

    name                 = "k8s-vpc"
    cidr                 = "172.16.0.0/16"
    azs                  = data.aws_availability_zones.available.names
    private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
    public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
    enable_nat_getaway   = true
    single_nat_getaway   = true
    enable_dns_hostnames = true

    public_subnets_tags = {
        "kubernetes.io/cluster/${local.cluster_name}" = "shared"
        "kubernetes.io/role/elb"                      = "1" 
    }

    private_subnets_tags = {
        "kubernetes.io/cluster/${local.cluster_name}"          = "shared"
        "kubernetes.io/role/internal-elb"                      = "1" 
    }
}

module "eks" {
    source     = "terraform-aws-modules/eks/aws"
    version    = "12.2.0"

    cluster_name    = "${local.cluster_name}"
    cluster_version = "1.71"
    subnets         = module.vpc.private_subnets

    vpc_id          = module.vpc.vpc_id


    node_groups = {
        first = {
            desired_capacity = 1 
            max_capacity     = 10
            min_capacity     = 1

            instance_type    = "t2.micro"
        }
    }

    write_kubeconfig    = true
    config_output_path  = "./"
}


data "aws_s3_bucket" "getbucket" {
    bucket   = "harry-bosch"
}

resource "aws_s3_bucket_object" "object" {
    bucket    = data.aws_s3_bucket.getbucket.id
    key       = module.eks.kubeconfig_filename
    source    = "./${module.eks.kubeconfig_filename}"
}
