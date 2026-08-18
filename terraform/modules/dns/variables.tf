variable "domain_name" {
  type        = string
  description = "The registered domain (e.g. akjames.dev). Must already be ACTIVE in Route 53 — this module only looks up the zone Route 53 auto-created at registration, it does not create one."
}

variable "eip_address" {
  type        = string
  description = "EC2 Elastic IP from the ec2 module; A records point here."
}
