output "github_ci_role_arn" {
  value       = aws_iam_role.github_ci.arn
  description = "For the AWS_ROLE_ARN repo variable on portfolio and ticker."
}

output "github_deploy_role_arn" {
  value       = aws_iam_role.github_deploy.arn
  description = "For the AWS_DEPLOY_ROLE_ARN repo variable on infra."
}

output "ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2.name
  description = "Attached to the EC2 instance in the ec2 module."
}
