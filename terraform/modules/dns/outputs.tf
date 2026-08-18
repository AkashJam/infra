output "zone_id" {
  value       = data.aws_route53_zone.primary.zone_id
  description = "Hosted zone ID, in case other records need adding later."
}
