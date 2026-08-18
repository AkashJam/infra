# Route 53 domain registration auto-creates the public hosted zone — this is
# a data-source lookup, not a fresh `aws_route53_zone` resource, which would
# create a second, conflicting zone with its own NS records.
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "apex" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [var.eip_address]
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.eip_address]
}

# Adopts the (already registered, out-of-band via CLI) domain into Terraform
# state so auto-renew/transfer-lock become code-managed going forward. This
# does not register the domain — aws_route53domains_domain would, but its
# multi-hour create latency would block the whole apply graph behind it, so
# registration itself happens imperatively via `aws route53domains
# register-domain`, outside of Terraform (see phase B of the Day 1-2 plan).
resource "aws_route53domains_registered_domain" "this" {
  domain_name = var.domain_name

  dynamic "name_server" {
    for_each = data.aws_route53_zone.primary.name_servers
    content {
      name = name_server.value
    }
  }
}
