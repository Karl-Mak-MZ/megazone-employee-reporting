output "bucket_name" {
  description = "Name of the S3 bucket for Athena query results and spill data"
  value       = aws_s3_bucket.athena.bucket
}

output "workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.main.name
}

output "catalog_name" {
  description = "Name of the Athena data catalog for DynamoDB"
  value       = aws_athena_data_catalog.dynamodb.name
}

output "connector_lambda_arn" {
  description = "ARN of the deployed DynamoDB connector Lambda function"
  value       = "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${var.catalog_name}"
}

output "sample_query" {
  description = "Example SQL query demonstrating CROSS JOIN UNNEST and LEFT JOIN across both DynamoDB tables"
  value       = <<-EOT
    SELECT
        e.employeeId,
        e.name,
        a.projectId,
        a.role,
        a.startDate AS assignmentStart,
        p.projectName,
        p.status AS projectStatus
    FROM "dynamodb"."default"."megazone-resource-planner-production-employees" e
    CROSS JOIN UNNEST(e.currentAssignments) AS t(a)
    LEFT JOIN "dynamodb"."default"."megazone-resource-planner-production-projects" p
        ON a.projectId = p.projectId
  EOT
}
