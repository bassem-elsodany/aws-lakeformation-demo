################################################################################
# Security group
################################################################################
module "redshift-sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/redshift"
  version = "~> 4.0"

  name   = "redshift-sg"
  vpc_id = module.vpc.vpc_id

  # Allow ingress rules to be accessed only within current VPC
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]

  # Allow all rules for all protocols
  egress_rules = ["all-all"]
}


################################################################################
# Redshift Cluster
################################################################################
module "redshift-cluster" {
  source  = "terraform-aws-modules/redshift/aws"
  version = "~> 3.0"

  cluster_identifier      = "my-cluster"
  cluster_node_type       = "dc2.large"
  cluster_number_of_nodes = 1

  cluster_database_name   = "${local.redshift_cluster_database_name}"
  cluster_master_username = "${local.redshift_cluster_master_username}"
  cluster_master_password = "${local.redshift_cluster_master_password}"

  subnets                = module.vpc.redshift_subnets
  vpc_security_group_ids = [module.redshift-sg.security_group_id]

  # IAM Roles
  cluster_iam_roles = [module.iam_assumable_role_redshift.iam_role_arn]
}