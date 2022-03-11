################################################################################
# S3 Buckets
################################################################################
resource "aws_s3_bucket" "datalake_s3_buckets" {
  count = "${length(local.s3_buckets)}"
  bucket = "${local.s3_buckets[count.index]}"
  force_destroy = true
  tags = local.tags
}

# S3 Athena Query Bucket
resource "aws_s3_bucket" "datalake_s3_athena_bucket" {
  bucket = "${local.s3_athena_query_bucket}"
  force_destroy = true
  tags = local.tags
}

# DataLake S3 ACL
resource "aws_s3_bucket_public_access_block" "datalake_s3_buckets_public_access_block" {
  count = "${length(local.s3_buckets)}"
  bucket = aws_s3_bucket.datalake_s3_buckets[count.index].id
  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets  = true
  ignore_public_acls = true
}

# Athena Query S3 ACL
resource "aws_s3_bucket_public_access_block" "datalake_s3_athena_buckets_public_access_block" {
  bucket = "${local.s3_athena_query_bucket}"
  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets  = true
  ignore_public_acls = true
}

# DataLake S3 Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "datalake_s3_buckets_sse" {
  count = "${length(local.s3_buckets)}"
  bucket = aws_s3_bucket.datalake_s3_buckets[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

# Athena Query S3 Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "datalake_s3_athena_buckets_sse" {
  bucket = "${local.s3_athena_query_bucket}"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}


# DataLake S3 Versioning
resource "aws_s3_bucket_versioning" "datalake_s3_buckets_versioning" {
  count = "${length(local.s3_buckets)}"
  bucket = aws_s3_bucket.datalake_s3_buckets[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Athena Query S3 Versioning
resource "aws_s3_bucket_versioning" "datalake_s3_athena_buckets_versioning" {
  bucket = "${local.s3_athena_query_bucket}"
  versioning_configuration {
    status = "Enabled"
  }
}

# DataLake S3 RAW Objects
resource "aws_s3_object" "raw_objects" {
    count = "${length(local.s3_buckets_raw_structure)}"
    bucket = aws_s3_bucket.datalake_s3_buckets.0.id
    key    = "${local.s3_buckets_raw_structure[count.index]}/"
}


# DataLake S3 Processed Objects
resource "aws_s3_object" "processed_objects" {
    count = "${length(local.s3_buckets_processed_structure)}"
    bucket = aws_s3_bucket.datalake_s3_buckets.1.id
    key    = "${local.s3_buckets_processed_structure[count.index]}/"
}


# DataLake S3 Curated Objects
resource "aws_s3_object" "curated_objects" {
    count = "${length(local.s3_buckets_curated_structure)}"
    bucket = aws_s3_bucket.datalake_s3_buckets.2.id
    key    = "${local.s3_buckets_curated_structure[count.index]}/"
}




# DataLake S3 RAW Customers Object
resource "aws_s3_object" "customers" {
  bucket = aws_s3_bucket.datalake_s3_buckets.0.id
  key    = "input/customers/customers.csv"
  acl    = "private"
  source = "raw-manifests/data/customers/customers.csv"
  etag   = filemd5("raw-manifests/data/customers/customers.csv")
}