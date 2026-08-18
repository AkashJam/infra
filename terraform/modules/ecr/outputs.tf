output "repository_urls" {
  description = "Map of image name -> ECR repository URL, for docker-compose.yml / CI."
  value = {
    portfolio = aws_ecr_repository.portfolio.repository_url
    ticker    = aws_ecr_repository.ticker.repository_url
  }
}

output "repository_arns" {
  description = "ECR repository ARNs, for scoping the GitHub CI role's push permissions."
  value = [
    aws_ecr_repository.portfolio.arn,
    aws_ecr_repository.ticker.arn,
  ]
}
