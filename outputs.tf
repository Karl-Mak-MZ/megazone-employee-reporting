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
  description = "Example SQL query demonstrating a federated LEFT JOIN across both DynamoDB tables filtered to assigned employees"
  value       = <<-EOT
    SELECT
      e.employeeId,
      e.fullName,
      e.assignmentStatus,
      e.role,
      e.department,
      a.projectName,
      p.projectDescription,
      p.status,
      p.clientName,
      a.role AS assignedRole,
      a.weeklyHours,
      a.duration,
      p.startDate,
      a.rate,
      a.vendor,
      a.projectId
    FROM "default"."megazone-resource-planner-production-employees" e
    CROSS JOIN UNNEST(e.currentAssignments) AS t(a)
    LEFT JOIN "default"."megazone-resource-planner-production-projects" p
      ON a.projectId = p.projectId
    ORDER BY e.fullName;
  EOT
}
