########################################
# Locals
########################################

locals {
  has_hub_public = length(var.hub_public_subnet_cidrs) > 0

  # NAT strategy helpers
  use_nat_single = var.hub_nat_strategy == "single" && local.has_hub_public
  use_nat_multi  = var.hub_nat_strategy == "multi"  && local.has_hub_public
  use_nat_any    = local.use_nat_single || local.use_nat_multi

  # Flow logs helpers
  flow_to_s3 = var.enable_vpc_flow_logs && var.flow_logs_destination_type == "s3"
  flow_to_cw = var.enable_vpc_flow_logs && var.flow_logs_destination_type == "cloudwatch"
  flow_s3_arn = var.flow_logs_s3_bucket_name != "" ? "arn:aws:s3:::${var.flow_logs_s3_bucket_name}" : null

  # Spokes by name for stable for_each keys
  spokes_by_name = {
    for s in var.spokes : s.name => s
  }

  # Flatten spoke private subnets: "spoke|az" => {spoke, az, cidr}
  spoke_private_flat = {
    for item in flatten([
      for spk, spec in local.spokes_by_name : [
        for az, cidr in spec.private_subnet_cidrs : {
          key   = "${spk}|${az}"
          spoke = spk
          az    = az
          cidr  = cidr
        }
      ]
    ]) : item.key => { spoke = item.spoke, az = item.az, cidr = item.cidr }
  }

  # Flatten spoke public subnets: "spoke|az" => {spoke, az, cidr}
  spoke_public_flat = {
    for item in flatten([
      for spk, spec in local.spokes_by_name : [
        for az, cidr in spec.public_subnet_cidrs : {
          key   = "${spk}|${az}"
          spoke = spk
          az    = az
          cidr  = cidr
        }
      ]
    ]) : item.key => { spoke = item.spoke, az = item.az, cidr = item.cidr }
  }

  tags_base = merge(
    { Module = "network" },
    var.tags
  )
}

########################################
# Hub VPC
########################################

# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags_base, { Name = "${var.prefix}-hub" })
}

# Hub private subnets (map of AZ => CIDR)
resource "aws_subnet" "hub_private" {
  for_each                = var.hub_private_subnet_cidrs
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false
  tags = merge(local.tags_base, {
    Name = "${var.prefix}-hub-private-${each.key}"
    Tier = "private"
  })
}

# Optional hub public subnets
# tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "hub_public" {
  for_each                = var.hub_public_subnet_cidrs
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = merge(local.tags_base, {
    Name = "${var.prefix}-hub-public-${each.key}"
    Tier = "public"
  })
}

# Optional IGW
resource "aws_internet_gateway" "hub" {
  count  = var.hub_create_internet_gateway && local.has_hub_public ? 1 : 0
  vpc_id = aws_vpc.hub.id
  tags   = merge(local.tags_base, { Name = "${var.prefix}-hub-igw" })
}

# Public route table + default route
resource "aws_route_table" "hub_public" {
  count  = var.hub_create_internet_gateway && local.has_hub_public ? 1 : 0
  vpc_id = aws_vpc.hub.id
  tags   = merge(local.tags_base, { Name = "${var.prefix}-hub-public-rt" })
}

resource "aws_route" "hub_public_igw" {
  count                  = length(aws_route_table.hub_public)
  route_table_id         = aws_route_table.hub_public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hub[0].id
}

resource "aws_route_table_association" "hub_public_assoc" {
  for_each       = length(aws_route_table.hub_public) > 0 ? aws_subnet.hub_public : {}
  route_table_id = aws_route_table.hub_public[0].id
  subnet_id      = each.value.id
}

########################################
# Hub NAT (single or multi)
########################################

# EIPs for NAT
resource "aws_eip" "hub_nat" {
  count      = local.use_nat_single ? 1 : (local.use_nat_multi ? length(aws_subnet.hub_public) : 0)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.hub]
  tags       = merge(local.tags_base, { Name = "${var.prefix}-hub-nat-eip-${count.index}" })
}

# Which public subnet(s) host NAT
locals {
  nat_host_subnet_ids = local.use_nat_single ? [
    aws_subnet.hub_public[sort(keys(aws_subnet.hub_public))[0]].id
  ] : (local.use_nat_multi ? [
    for _, s in aws_subnet.hub_public : s.id
  ] : [])
}

resource "aws_nat_gateway" "hub" {
  count         = length(local.nat_host_subnet_ids)
  subnet_id     = element(local.nat_host_subnet_ids, count.index)
  allocation_id = aws_eip.hub_nat[count.index].id
  depends_on    = [aws_internet_gateway.hub]
  tags          = merge(local.tags_base, { Name = "${var.prefix}-hub-nat-${count.index}" })
}

# Private route tables per AZ
resource "aws_route_table" "hub_private" {
  for_each = aws_subnet.hub_private
  vpc_id   = aws_vpc.hub.id
  tags     = merge(local.tags_base, { Name = "${var.prefix}-hub-private-rt-${each.key}" })
}

# Default route to NAT (if configured)
resource "aws_route" "hub_private_default" {
  for_each               = local.use_nat_any ? aws_route_table.hub_private : {}
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = local.use_nat_single ? aws_nat_gateway.hub[0].id : (
    local.use_nat_multi ?
      aws_nat_gateway.hub[index(sort(keys(aws_subnet.hub_public)), each.key)].id
      : null
  )
}

resource "aws_route_table_association" "hub_private_assoc" {
  for_each       = aws_subnet.hub_private
  route_table_id = aws_route_table.hub_private[each.key].id
  subnet_id      = each.value.id
}

########################################
# Transit Gateway (optional)
########################################

resource "aws_ec2_transit_gateway" "this" {
  count                                   = var.create_transit_gateway ? 1 : 0
  auto_accept_shared_attachments          = var.tgw_auto_accept_shared_attachments
  default_route_table_association         = var.tgw_default_route_table_association
  default_route_table_propagation         = var.tgw_default_route_table_propagation
  tags                                    = merge(local.tags_base, { Name = "${var.prefix}-tgw" })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  count              = var.create_transit_gateway ? 1 : 0
  vpc_id             = aws_vpc.hub.id
  subnet_ids         = [for s in aws_subnet.hub_private : s.id]
  transit_gateway_id = aws_ec2_transit_gateway.this[0].id
  tags               = merge(local.tags_base, { Name = "${var.prefix}-hub-attach" })
}

########################################
# Spoke VPCs
########################################

# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "spoke" {
  for_each             = local.spokes_by_name
  cidr_block           = each.value.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.tags_base, { Name = "${var.prefix}-${each.key}" })
}

# Spoke private subnets (flattened)
resource "aws_subnet" "spoke_private" {
  for_each                = local.spoke_private_flat
  vpc_id                  = aws_vpc.spoke[each.value.spoke].id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
  tags = merge(local.tags_base, {
    Name = "${var.prefix}-${each.value.spoke}-private-${each.value.az}"
    Tier = "private"
  })
}

# Spoke public subnets (flattened, optional)
# tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "spoke_public" {
  for_each                = local.spoke_public_flat
  vpc_id                  = aws_vpc.spoke[each.value.spoke].id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(local.tags_base, {
    Name = "${var.prefix}-${each.value.spoke}-public-${each.value.az}"
    Tier = "public"
  })
}

# Per‑spoke IGW (if requested and there are public subnets)
resource "aws_internet_gateway" "spoke" {
  for_each = {
    for k, s in local.spokes_by_name :
    k => s if (s.create_internet_gateway && length(s.public_subnet_cidrs) > 0)
  }
  vpc_id = aws_vpc.spoke[each.key].id
  tags   = merge(local.tags_base, { Name = "${var.prefix}-${each.key}-igw" })
}

# Spoke public route tables + default routes
resource "aws_route_table" "spoke_public" {
  for_each = aws_internet_gateway.spoke
  vpc_id   = aws_vpc.spoke[each.key].id
  tags     = merge(local.tags_base, { Name = "${var.prefix}-${each.key}-public-rt" })
}

resource "aws_route" "spoke_public_igw" {
  for_each               = aws_internet_gateway.spoke
  route_table_id         = aws_route_table.spoke_public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.spoke[each.key].id
}

resource "aws_route_table_association" "spoke_public_assoc" {
  for_each = local.spoke_public_flat
  route_table_id = aws_route_table.spoke_public[each.value.spoke].id
  subnet_id      = aws_subnet.spoke_public[each.key].id
}

# Spoke private route tables (one per private subnet AZ)
resource "aws_route_table" "spoke_private" {
  for_each = local.spoke_private_flat
  vpc_id   = aws_vpc.spoke[each.value.spoke].id
  tags     = merge(local.tags_base, { Name = "${var.prefix}-${each.value.spoke}-private-rt-${each.value.az}" })
}

resource "aws_route_table_association" "spoke_private_assoc" {
  for_each       = local.spoke_private_flat
  route_table_id = aws_route_table.spoke_private[each.key].id
  subnet_id      = aws_subnet.spoke_private[each.key].id
}

# TGW attachments for spokes (to private subnets)
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke" {
  for_each = var.create_transit_gateway ? { for n in keys(local.spokes_by_name) : n => n } : {}
  vpc_id   = aws_vpc.spoke[each.key].id
  subnet_ids = [
    for k, v in local.spoke_private_flat :
    aws_subnet.spoke_private[k].id if v.spoke == each.key
  ]
  transit_gateway_id = aws_ec2_transit_gateway.this[0].id
  tags               = merge(local.tags_base, { Name = "${var.prefix}-${each.key}-attach" })
}

########################################
# VPC Flow Logs (Hub + Spokes)
########################################

# Hub → S3
resource "aws_flow_log" "hub_s3" {
  count                = local.flow_to_s3 ? 1 : 0
  log_destination_type = "s3"
  log_destination      = local.flow_s3_arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.hub.id
  tags                 = merge(local.tags_base, { Name = "${var.prefix}-hub-flowlogs-s3" })
}

# Hub → CloudWatch
resource "aws_cloudwatch_log_group" "flow_hub" {
  count             = local.flow_to_cw ? 1 : 0
  name              = var.flow_logs_log_group_name
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.flow_logs_kms_key_id != "" ? var.flow_logs_kms_key_id : null
  tags              = merge(local.tags_base, { Name = "${var.prefix}-hub-flowlogs" })
}

resource "aws_iam_role" "flowlogs_role" {
  count = local.flow_to_cw ? 1 : 0
  name  = "${var.prefix}-vpc-flowlogs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
  tags = local.tags_base
}

# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "flowlogs_role_policy" {
  count = local.flow_to_cw ? 1 : 0
  name  = "${var.prefix}-vpc-flowlogs-policy"
  role  = aws_iam_role.flowlogs_role[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"],
      Resource = "${aws_cloudwatch_log_group.flow_hub[0].arn}:*" # stream-level ARN required by AWS
    }]
  })
}

resource "aws_flow_log" "hub_cw" {
  count                = local.flow_to_cw ? 1 : 0
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_hub[0].arn
  iam_role_arn         = aws_iam_role.flowlogs_role[0].arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.hub.id
  tags                 = merge(local.tags_base, { Name = "${var.prefix}-hub-flowlogs-cw" })
}

resource "aws_flow_log" "spoke_cw" {
  for_each             = local.flow_to_cw ? aws_vpc.spoke : {}
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_hub[0].arn
  iam_role_arn         = aws_iam_role.flowlogs_role[0].arn
  traffic_type         = "ALL"
  vpc_id               = each.value.id
  tags                 = merge(local.tags_base, { Name = "${var.prefix}-${each.key}-flowlogs-cw" })
}


# Spokes → same destination choice as Hub

resource "aws_flow_log" "spoke_s3" {
  for_each = local.flow_to_s3 ? aws_vpc.spoke : {}
  log_destination_type = "s3"
  log_destination      = local.flow_s3_arn
  traffic_type         = "ALL"
  vpc_id               = each.value.id
  tags                 = merge(local.tags_base, { Name = "${var.prefix}-${each.key}-flowlogs-s3" })
}


