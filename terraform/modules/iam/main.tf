resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # thumbprint_list intentionally omitted: AWS validates this well-known
  # provider's certificate chain automatically, so a manually pinned
  # thumbprint is no longer required (verified against current provider
  # behavior at the time this was written).
}

# --- GitHub Actions CI role (portfolio, ticker): ECR push only ------------

data "aws_iam_policy_document" "github_ci_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Wildcarded around owner/repo rather than an exact "owner/repo:*"
      # match: GitHub's sub claim is "repo:OWNER/REPO:ref:..." for repos
      # without immutable-ID subject claims enabled, but
      # "repo:OWNER@owner_id/REPO@repo_id:ref:..." for repos with it on
      # (confirmed against this project's actual issued token). Matches both
      # without hardcoding account-specific numeric IDs into HCL.
      values = [for repo in var.github_ci_repos : "repo:${var.github_owner}*/${repo}*:*"]
    }
  }
}

resource "aws_iam_role" "github_ci" {
  name               = "${var.project_name}-github-ci"
  assume_role_policy = data.aws_iam_policy_document.github_ci_trust.json
}

data "aws_iam_policy_document" "github_ci_policy" {
  statement {
    sid       = "ECRAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # this action has no resource-level permissions
  }

  statement {
    sid    = "ECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = var.ecr_repo_arns
  }
}

resource "aws_iam_role_policy" "github_ci" {
  name   = "${var.project_name}-github-ci-ecr-push"
  role   = aws_iam_role.github_ci.id
  policy = data.aws_iam_policy_document.github_ci_policy.json
}

# --- GitHub Actions deploy role (infra, main branch only) -----------------

data "aws_iam_policy_document" "github_deploy_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # StringLike, not StringEquals — see the matching comment on
      # github_ci_trust above; an exact-match test can't tolerate GitHub's
      # immutable-ID subject claim format at all.
      values = ["repo:${var.github_owner}*/${var.github_deploy_repo}*:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${var.project_name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_deploy_trust.json
}

data "aws_iam_policy_document" "github_deploy_policy" {
  statement {
    sid       = "SendCommand"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    # Scoped by tag instead of instance ARN/ID to avoid a circular module
    # dependency (this role is created before the EC2 instance exists);
    # deploy.yml resolves the instance the same way, by Name tag.
    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/Name"
      values   = ["${var.project_name}-${var.environment}"]
    }
  }

  statement {
    sid       = "SendCommandDocument"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
  }

  statement {
    sid    = "GetCommandInvocation"
    effect = "Allow"
    # Left unscoped (resources = "*"): GetCommandInvocation is identified by
    # command-id, not the instance resource, and its exact resource-level
    # ARN grammar isn't something I could verify without live testing —
    # chose to not risk silently breaking the deploy workflow's status
    # polling over a marginal scoping gain.
    actions   = ["ssm:GetCommandInvocation"]
    resources = ["*"]
  }

  statement {
    sid       = "DescribeInstances"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"] # Describe* actions don't support resource-level scoping
  }

  statement {
    sid       = "PutReleaseArtifacts"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${var.releases_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name   = "${var.project_name}-github-deploy"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy_policy.json
}

# --- EC2 instance role (the box itself) ------------------------------------

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_instance" {
  name               = "${var.project_name}-ec2-instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    sid       = "ECRAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPull"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = var.ecr_repo_arns
  }

  statement {
    sid    = "SSMParams"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:*:*:parameter/${var.project_name}/${var.environment}/*"]
  }

  statement {
    sid       = "ReleaseArtifactsRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.releases_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "ec2_instance" {
  name   = "${var.project_name}-ec2-instance"
  role   = aws_iam_role.ec2_instance.id
  policy = data.aws_iam_policy_document.ec2_policy.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-instance"
  role = aws_iam_role.ec2_instance.name
}
