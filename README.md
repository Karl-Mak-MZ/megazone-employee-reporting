# Athena DynamoDB Connector — Terraform Module

Terraform module that provisions AWS infrastructure to enable querying DynamoDB tables through Amazon Athena using a federated query connector.

The module deploys the AWS-provided [AthenaDynamoDBConnector](https://serverlessrepo.aws.amazon.com/applications/us-east-1/292517598671/AthenaDynamoDBConnector) Lambda from the Serverless Application Repository, registers it as an Athena data catalog, creates a dedicated Athena workgroup (engine v3), and provisions a single S3 bucket for both query results and Lambda spill data.

> **Note:** This module does **NOT** create or manage the DynamoDB tables. They must already exist in your AWS account.

## Prerequisites

- Terraform >= 1.0
- AWS provider >= 5.0
- Two pre-existing DynamoDB tables in the target AWS account and region

## Usage

```hcl
module "athena_dynamodb" {
  source = "./"

  aws_region         = "us-east-1"
  bucket_name        = "megazone-athena-bucket-karl-makuvaro2"
  workgroup_name     = "megazone-dynamodb-workgroup-karl-makuvaro"
  catalog_name       = "dynamodb-karl-makuvaro"
  lambda_memory_size = 1024
  lambda_timeout     = 900
}
```

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `"us-east-1"` | AWS region for all resources |
| `bucket_name` | `string` | `"megazone-athena-bucket-karl-makuvaro2"` | Name for the S3 bucket (query results + spill data) |
| `workgroup_name` | `string` | `"megazone-dynamodb-workgroup-karl-makuvaro"` | Name for the Athena workgroup |
| `catalog_name` | `string` | `"dynamodb-karl-makuvaro"` | Name for the Athena data catalog |
| `lambda_memory_size` | `number` | `1024` | Memory in MB for the DynamoDB connector Lambda function |
| `lambda_timeout` | `number` | `900` | Timeout in seconds for the DynamoDB connector Lambda function |

## Outputs

| Output | Description |
|---|---|
| `bucket_name` | Name of the S3 bucket for Athena query results and spill data |
| `workgroup_name` | Name of the Athena workgroup |
| `catalog_name` | Name of the Athena data catalog for DynamoDB |
| `connector_lambda_arn` | ARN of the deployed DynamoDB connector Lambda function |
| `sample_query` | Example SQL query demonstrating CROSS JOIN UNNEST and LEFT JOIN across both tables |

## Sample Federated Query

Once the module is applied, you can run the following query in the Athena workgroup to join employee assignments with project details:

```sql
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
```

This query:

1. Reads from the employees table via the `dynamodb` federated catalog
2. Flattens the nested `currentAssignments` list into individual rows using `CROSS JOIN UNNEST`
3. Joins each assignment to the projects table on `projectId` using `LEFT JOIN`
4. Requires Athena engine v3 (configured by the workgroup) for federated query and UNNEST support

## Architecture

The module creates the following resources:

- **S3 Bucket** — stores Athena query results (`Query-Results/` prefix) and Lambda spill data (`spill/` prefix), with versioning, SSE-S3 encryption, and public access blocked
- **IAM Role** — least-privilege execution role for the connector Lambda with DynamoDB read, S3 write, and CloudWatch Logs permissions
- **Connector Lambda** — deployed from the AWS Serverless Application Repository (`AthenaDynamoDBConnector`)
- **Athena Data Catalog** — LAMBDA-type catalog that routes queries to the connector Lambda
- **Athena Workgroup** — dedicated workgroup with engine v3, enforced result output location, and ENABLED state
