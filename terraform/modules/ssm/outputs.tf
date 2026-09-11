output "grafana_admin_password" {
  value     = aws_ssm_parameter.grafana_admin_password.value
  sensitive = true
}
