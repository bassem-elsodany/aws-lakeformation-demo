resource "random_password" "master" {
  length = 10
}

################################################################################
# SG
################################################################################
module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "sg_${local.name}-db"
  description = "${local.environment}-DB security group"
  vpc_id      = module.vpc.vpc_id

  # ingress    
  ingress_with_cidr_blocks = [
    {
      rule                     = "mysql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule                     = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  # Open for security group id (rule or from_port+to_port+protocol+description)
  ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.db_security_group.security_group_id
    },    
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.db_security_group.security_group_id
    },
    {
      from_port = 0
      to_port = 65535
      protocol = "-1"
      source_security_group_id = module.db_security_group.security_group_id
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule = "all-all"
    },
  ]

  tags = local.tags
}

################################################################################
# RDS Subnet Groups
################################################################################
resource "aws_db_subnet_group" "mysqlgroup" {
  description = "Created from the RDS Management Console"
  name        = "mysql-subnet-group"
  subnet_ids  = [module.vpc.database_subnets[0],module.vpc.database_subnets[2]]
}

resource "aws_db_subnet_group" "postgresgroup" {
  description = "Created from the RDS Management Console"
  name        = "postgres-subnet-group"
  subnet_ids  = [module.vpc.database_subnets[1],module.vpc.database_subnets[2]]
}

################################################################################
# MYSQL RDS
################################################################################
module "mysql-db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "lakeformationmysqltickit"
  db_name  = "tickit"

  engine               = "mysql"
  engine_version       = "5.7.37"
  family               = "mysql5.7" # DB parameter group
  major_engine_version = "5.7"      # DB option group
  instance_class       = "db.t2.micro"

  allocated_storage     = 20
  max_allocated_storage = 1000
  storage_encrypted = false


  username = "lakeformationmysqltickit"
  port     = 3306

  multi_az               = false
  availability_zone      = "${local.region}a"
  #subnet_ids             = [module.vpc.database_subnets[0]]
  db_subnet_group_name   =  "${aws_db_subnet_group.mysqlgroup.name}"

  vpc_security_group_ids = [module.db_security_group.security_group_id]

  publicly_accessible   = true
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.tags
  db_instance_tags = {
    "Sensitive" = "high"
  }
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
}

################################################################################
# Postgres RDS
################################################################################
module "postgres-db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "lakeformationpostgrestickit"
  db_name  = "tickit"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "12.9"
  family               = "postgres12"
  major_engine_version = "12"
  instance_class       = "db.t2.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted = false

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"

  username = "lakeformationpostgrestickit"
  port     = 5432

  publicly_accessible   = true
  availability_zone      = "${local.region}b"
  multi_az               = false
  #subnet_ids             = [module.vpc.database_subnets[1]]
  db_subnet_group_name   =  "${aws_db_subnet_group.postgresgroup.name}"
  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = false

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "example-monitoring-role-name"
  monitoring_role_description           = "Description for monitoring role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}