# S3 Bucket for Athena query results and Lambda spill data
resource "aws_s3_bucket" "athena" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "athena" {
  bucket = aws_s3_bucket.athena.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena" {
  bucket = aws_s3_bucket.athena.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "athena" {
  bucket = aws_s3_bucket.athena.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data sources for dynamic ARN construction
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM Role for the DynamoDB Connector Lambda
resource "aws_iam_role" "connector" {
  name = "athena-dynamodb-connector-role-karl-makuvaro"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "connector" {
  name = "athena-dynamodb-connector-policy-karl-makuvaro"
  role = aws_iam_role.connector.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:BatchGetItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:table/megazone-resource-planner-production-employees",
          "arn:aws:dynamodb:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:table/megazone-resource-planner-production-projects"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.athena.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.athena.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Connector Lambda via AWS Serverless Application Repository
resource "aws_serverlessapplicationrepository_cloudformation_stack" "connector" {
  name           = var.catalog_name
  application_id = "arn:aws:serverlessrepo:us-east-1:292517598671:applications/AthenaDynamoDBConnector"
  capabilities   = ["CAPABILITY_IAM", "CAPABILITY_RESOURCE_POLICY"]

  parameters = {
    SpillBucket       = aws_s3_bucket.athena.bucket
    SpillPrefix       = "spill/"
    AthenaCatalogName = var.catalog_name
    LambdaMemory      = tostring(var.lambda_memory_size)
    LambdaTimeout     = tostring(var.lambda_timeout)
  }
}

# Athena Data Catalog for DynamoDB
resource "aws_athena_data_catalog" "dynamodb" {
  name        = var.catalog_name
  description = "Athena data catalog for querying DynamoDB tables via federated query"
  type        = "LAMBDA"

  parameters = {
    "function" = "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${var.catalog_name}"
  }

  depends_on = [aws_serverlessapplicationrepository_cloudformation_stack.connector]
}

# Athena Workgroup
resource "aws_athena_workgroup" "main" {
  name  = var.workgroup_name
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena.bucket}/Query-Results/"
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }
}
