output "eip_address" {
  value       = aws_eip.app.public_ip
  description = "Public IP the dns module points A records at."
}

output "instance_id" {
  value       = aws_instance.app.id
  description = "For reference; deploy.yml resolves this itself by 'Name' tag rather than hardcoding it."
}
