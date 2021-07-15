module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.1.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.20"

  tags = {
    Environment = "training"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 2
      root_volume_type              = "gp2"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
    }
  ]
}
