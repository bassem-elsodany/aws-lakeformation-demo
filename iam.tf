data "aws_iam_policy_document" "buckets_policy" {
    statement {
      actions = ["s3:GetObject","s3:PutObject","s3:DeleteObject"]
      resources = [for k in local.s3_buckets : "arn:aws:s3:::${k}"]
  }
    statement {
      actions = ["s3:GetObject","s3:PutObject","s3:DeleteObject"]
      resources = [for k in local.s3_buckets : "arn:aws:s3:::${k}/*"]
  }
}


################################################################################
# IAM User
################################################################################

# LakeFormation Admin User
module "iam_user_admin_lakeformation" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name = "${local.name}-admin-user"

  create_iam_user_login_profile = true
  create_iam_access_key         = true
  password_reset_required       = false
}

# LakeFormation Analyst User
module "iam_user_analyst_lakeformation" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name = "${local.name}-analyst-user"

  create_iam_user_login_profile = true
  create_iam_access_key         = true
  password_reset_required       = false
}

################################################################################
# IAM Group
################################################################################

# LakeFormation Admin Group
module "iam_group_lakeformation_admin" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "${local.name}-admin-group"

  group_users = [
    module.iam_user_admin_lakeformation.iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
    "arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin",
  ]
}

# LakeFormation Analyst Group
module "iam_group_lakeformation_analyst" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "${local.name}-analyst-group"

  group_users = [
    module.iam_user_analyst_lakeformation.iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonAthenaFullAccess",
  ]
    custom_group_policies = [
    {
      name   = "AllowS3ForAthenaQuery"
      policy = data.aws_iam_policy_document.athena_query.json
    },    
    {
      name   = "AllowS3Read"
      policy = data.aws_iam_policy_document.athena_data.json
    }
  ]
}

################################################################################
# IAM Policy
################################################################################
# Athena Queries
data "aws_iam_policy_document" "athena_query" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
    "arn:aws:s3:::${local.s3_athena_query_bucket}",
    "arn:aws:s3:::${local.s3_athena_query_bucket}/*"
     ]
  }
}

data "aws_iam_policy_document" "athena_data" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = [
    "arn:aws:s3:::${local.s3_buckets[1]}/*",
    "arn:aws:s3:::${local.s3_buckets[2]}/*"
     ]
  }
}

module "iam_policy_lakeformation" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4"

  name        = "${local.name}-policy"
  path        = "/"
  description = "${local.name}-policy"

  policy = data.aws_iam_policy_document.buckets_policy.json
}

resource "aws_iam_policy" "glue_policy" {
  name        = "DatalakeUserBasic"
  path        = "/"
  description = "Policy for AWS Glue service role which allows access to related services including EC2, S3, and Cloudwatch Logs"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lakeformation:GetDataAccess",
                "glue:GetTable",
                "glue:GetTables",
                "glue:SearchTables",
                "glue:GetDatabase",
                "glue:GetDatabases",
                "glue:GetPartitions",
                "lakeformation:GetResourceLFTags",
                "lakeformation:ListLFTags",
                "lakeformation:GetLFTag",
                "lakeformation:SearchTablesByLFTags",
                "lakeformation:SearchDatabasesByLFTags",
                "lakeformation:GetWorkUnits",
                "lakeformation:StartQueryPlanning",
                "lakeformation:GetWorkUnitResults",
                "lakeformation:GetQueryState",
                "lakeformation:GetQueryStatistics"
           ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_group_policy_attachment" "glue_attach" {
  group       = module.iam_group_lakeformation_analyst.group_name
  policy_arn = aws_iam_policy.glue_policy.arn
}
################################################################################
# IAM Role
################################################################################

module "iam_assumable_role_lakeformation" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4"

  #trusted_role_arns = [
   # module.iam_user_admin_lakeformation.iam_user_arn,
  #]

  trusted_role_services = [
    "glue.amazonaws.com"
  ]

  create_role = true
  role_name         = "${local.name}-role"
  role_requires_mfa = false
  attach_admin_policy = true

  tags = {
    Role = "Admin"
  }

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
     module.iam_policy_lakeformation.arn,
  ]
   # number_of_custom_role_policy_arns = 2
}


### Kinesis firehose Role
resource "aws_iam_role" "firehose_role" {
  name = "${local.name}-firehose_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  dynamic "inline_policy" {
    for_each = local.kinesis_destination_type == "extended_s3" ? [true] : []
    content {
      name = "s3_destination_access"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [{
          "Effect" : "Allow",
          "Action" : [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          "Resource" : [
            "arn:aws:s3:::${local.s3_buckets[0]}",
            "arn:aws:s3:::${local.s3_buckets[0]}/*"
          ]
        }]
      })
    }
  }

}


### Redshift Role
module "iam_assumable_role_redshift" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4"

  trusted_role_services = [
    "redshift.amazonaws.com"
  ]

  create_role = true
  role_name         = "${local.name}-redshift-role"
  role_requires_mfa = false
  attach_admin_policy = true

  tags = {
    Role = "redshift-Admin"
  }

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess"
  ]
}






