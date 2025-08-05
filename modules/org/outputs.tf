output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.current.id
}

output "ou_ids" {
  description = "Map of OU names to their IDs"
  value = {
    for name in var.organizational_units :
    name => aws_organizations_organizational_unit.ou[name].id
  }
}