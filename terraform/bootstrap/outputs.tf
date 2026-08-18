output "state_bucket" {
  value       = aws_s3_bucket.tfstate.id
  description = "Name of the S3 bucket holding Terraform remote state. Copy this into environments/prod/backend.hcl."
}
