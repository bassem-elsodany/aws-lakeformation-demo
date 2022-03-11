locals {
  name   = "lakeformation-demo"
  region = "eu-west-2"
  environment = "development"
  bu = "IT"
  s3_buckets = ["epam-lakeformation-demo-raw","epam-lakeformation-demo-processed","epam-lakeformation-demo-curated"]
  s3_athena_query_bucket = "epam-athena-queries"
  s3_buckets_raw_structure = ["input/customers","input/kinesis-stream","input/mysql","input/postgresql","output"]
  s3_buckets_processed_structure = ["input/customers","input/kinesis-stream","input/tickit"]
  s3_buckets_curated_structure = ["input/customers","input/kinesis-stream","input/tickit"]
  kinesis_destination_type = "extended_s3"
  redshift_cluster_database_name   = "test"
  redshift_cluster_master_username = "mydbuser"
  redshift_cluster_master_password = "MySecretPassw0rd"
  tags = {
    Owner       = "lakeformation"
    Environment = "development"
    BU = "IT"
  }
}

data "aws_caller_identity" "current" {}