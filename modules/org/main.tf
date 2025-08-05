
resource "aws_organizations_organization" "root_org" {
  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "ou" {
  for_each  = toset(var.organizational_units)
  name      = each.value
  parent_id = aws_organizations_organization.root_org.roots[0].id
}

resource "aws_organizations_policy_attachment" "attach_scp" {
  for_each  = aws_organizations_organizational_unit.ou
  policy_id = var.scp_policies.DenyGlobalServices
  target_id = each.value.id
}