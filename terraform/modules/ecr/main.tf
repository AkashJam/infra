resource "aws_ecr_repository" "portfolio" {
  name = "portfolio"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ticker" {
  name = "ticker"

  image_scanning_configuration {
    scan_on_push = true
  }
}

locals {
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "portfolio" {
  repository = aws_ecr_repository.portfolio.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "ticker" {
  repository = aws_ecr_repository.ticker.name
  policy     = local.lifecycle_policy
}
