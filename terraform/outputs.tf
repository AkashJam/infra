output "github_ci_role_arn" {
  value       = module.iam.github_ci_role_arn
  description = "Set as the AWS_ROLE_ARN repo variable on portfolio and ticker."
}

output "github_deploy_role_arn" {
  value       = module.iam.github_deploy_role_arn
  description = "Set as the AWS_DEPLOY_ROLE_ARN repo variable on infra."
}

output "releases_bucket" {
  value       = aws_s3_bucket.releases.id
  description = "Set as the RELEASE_BUCKET repo variable on infra."
}

output "ecr_repository_urls" {
  value       = module.ecr.repository_urls
  description = "ECR push targets for portfolio/ticker CI."
}

output "instance_public_ip" {
  value       = module.ec2.eip_address
  description = "The box's public IP — should match what akjames.dev resolves to."
}
