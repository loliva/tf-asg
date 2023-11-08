module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"
  #acl = "private"
  bucket        = lower("vpc-flow-${random_string.suffix.result}")
  policy        = data.aws_iam_policy_document.flow_log_s3.json
  force_destroy = true
  tags = local.tags
}

data "aws_iam_policy_document" "flow_log_s3" {
  statement {
    sid = "AWSLogDeliveryWrite"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = ["${module.s3_bucket.s3_bucket_arn}/AWSLogs/*"]
  }
  statement {
    sid = "AWSLogDeliveryAclCheck"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:GetBucketAcl"]
    resources = ["${module.s3_bucket.s3_bucket_arn}"]
  }
}

