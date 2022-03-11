################################################################################
# KINESIS Firehose Delivery Stream
################################################################################
resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "kinesis-firehose-s3-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.datalake_s3_buckets.0.arn
    prefix = "${local.s3_buckets_raw_structure[1]}/"
    buffer_interval = 60
    buffer_size= 1

    processing_configuration {
      enabled = "false"
    }
  }
}