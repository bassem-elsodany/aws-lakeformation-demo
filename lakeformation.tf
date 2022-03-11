################################################################################
# LakeFormation Security
################################################################################
resource "aws_lakeformation_data_lake_settings" "admin" {
  admins = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole",module.iam_user_admin_lakeformation.iam_user_arn,]
}

################################################################################
# LAKE DATABASE
################################################################################
resource "aws_glue_catalog_database" "lakeformation-database" {
  depends_on  = [aws_s3_bucket.datalake_s3_buckets]
  count = "${length(local.s3_buckets)}"
  location_uri = "s3://${local.s3_buckets[count.index]}"
  name         = "${local.s3_buckets[count.index]}"

  create_table_default_permission {
    permissions = ["ALL"]

    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }

}

################################################################################
# LAKE DATABASE PERMISSIONS
################################################################################
resource "aws_lakeformation_permissions" "lakeformation-database-permission" {
  count = "${length(aws_glue_catalog_database.lakeformation-database)}"
  principal = module.iam_assumable_role_lakeformation.iam_role_arn
  permissions                   = ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]
  permissions_with_grant_option = ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]

  database {
    name       = "${aws_glue_catalog_database.lakeformation-database[count.index].name}"
  }
}

# Kinesis LAKE DATABASE PERMISSIONS
resource "aws_lakeformation_permissions" "lakeformation-database-permission-kinesis" {
  count = "${length(aws_glue_catalog_database.lakeformation-database)}"
  principal = aws_iam_role.firehose_role.arn
  permissions                   = ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]
  permissions_with_grant_option = ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]

  database {
    name       = "${aws_glue_catalog_database.lakeformation-database[count.index].name}"
  }
}


# Redshift LAKE DATABASE PERMISSIONS
resource "aws_lakeformation_permissions" "lakeformation-database-permission-redshift" {
  count = "${length(aws_glue_catalog_database.lakeformation-database)}"
  principal = module.iam_assumable_role_redshift.iam_role_arn
  permissions                   = ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]
  permissions_with_grant_option = ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]

  database {
    name       = "${aws_glue_catalog_database.lakeformation-database[count.index].name}"
  }
}