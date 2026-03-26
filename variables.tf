variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources"
}

variable "bucket_name" {
  type        = string
  default     = "megazone-athena-bucket-karl-makuvaro2"
  description = "Name for the S3 bucket used for Athena query results and Lambda spill data"
}

variable "workgroup_name" {
  type        = string
  default     = "megazone-dynamodb-workgroup-karl-makuvaro"
  description = "Name for the Athena workgroup"
}

variable "catalog_name" {
  type        = string
  default     = "dynamodb-karl-makuvaro"
  description = "Name for the Athena data catalog"
}

variable "lambda_memory_size" {
  type        = number
  default     = 1024
  description = "Memory in MB for the DynamoDB connector Lambda function"
}

variable "lambda_timeout" {
  type        = number
  default     = 900
  description = "Timeout in seconds for the DynamoDB connector Lambda function"
}
