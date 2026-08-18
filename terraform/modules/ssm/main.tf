# Near-empty for Day 1-2 — proves the module and the naming convention that
# the ec2 module's instance role is scoped to read
# (/${project_name}/${environment}/*). Real DB credentials land in Days 5-9
# (portfolio.md §15) as more aws_ssm_parameter "SecureString" resources
# under this same path.

resource "aws_ssm_parameter" "placeholder" {
  name  = "/${var.project_name}/${var.environment}/placeholder"
  type  = "String"
  value = "placeholder - real params land in Days 5-9"
}
