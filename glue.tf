################################################################################
# GLUE CONNECTIONS
################################################################################

# Mysql
resource "aws_glue_connection" "mysql_connection" {

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${module.mysql-db.db_instance_endpoint}/tickit"
    PASSWORD            = module.mysql-db.db_instance_password
    USERNAME            = module.mysql-db.db_instance_username
  }

  name = "tickit_mysql_source"

  physical_connection_requirements {
    availability_zone      = "${local.region}a"
    security_group_id_list = [module.db_security_group.security_group_id]
    subnet_id              = tolist(module.vpc.database_subnets)[0]
  }
}

# Postgresql
resource "aws_glue_connection" "postgresql_connection" {

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${module.postgres-db.db_instance_endpoint}/tickit"
    PASSWORD            = module.postgres-db.db_instance_password
    USERNAME            = module.postgres-db.db_instance_username
  }

  name = "tickit_postgresql_source"

  physical_connection_requirements {
    availability_zone      = "${local.region}b"
    security_group_id_list = [module.db_security_group.security_group_id]
    subnet_id              = tolist(module.vpc.database_subnets)[1]
  }
}


# Redshift
resource "aws_glue_connection" "redshift_connection" {

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:redshift://${module.redshift-cluster.redshift_cluster_endpoint}/${local.redshift_cluster_database_name}"
    PASSWORD            = "${local.redshift_cluster_master_password}"
    USERNAME            = "${local.redshift_cluster_master_username}"
  }

  name = "redshift_connection"

  physical_connection_requirements {
    availability_zone      = "${module.redshift-cluster.redshift_cluster_availability_zone}"
    security_group_id_list = module.redshift-cluster.redshift_cluster_vpc_security_group_ids
    subnet_id              = tolist(module.vpc.redshift_subnets)[0]
  }
}

################################################################################
# GLUE CRAWLER
################################################################################
# S3 Customers CRAWLER
resource "aws_glue_crawler" "raw_customer_ingest" {
  database_name = aws_glue_catalog_database.lakeformation-database.0.name
  name          = "raw-customers-ingest"
  role          = module.iam_assumable_role_lakeformation.iam_role_arn

  s3_target {
    path = "s3://${local.s3_buckets[0]}/${local.s3_buckets_raw_structure[0]}"
  }
}
# Kinesis CRAWLER
resource "aws_glue_crawler" "raw_kinesis_ingest" {
  database_name = aws_glue_catalog_database.lakeformation-database.0.name
  name          = "raw-kinesis-ingest"
  role          = module.iam_assumable_role_lakeformation.iam_role_arn

  s3_target {
    path = "s3://${local.s3_buckets[0]}/${local.s3_buckets_raw_structure[1]}"
  }
}

# Redshift CRAWLER
resource "aws_glue_crawler" "processed_redshift" {
  database_name = aws_glue_catalog_database.lakeformation-database.0.name
  table_prefix = "redshift_"
  name          = "raw-redshift"
  role          = module.iam_assumable_role_lakeformation.iam_role_arn

  jdbc_target {
    connection_name = "redshift_connection"
    path            = "${local.redshift_cluster_database_name}/public/%"
  }
}
################################################################################
# GLUE JOBS
################################################################################