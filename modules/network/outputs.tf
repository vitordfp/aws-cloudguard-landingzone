########################################
# Hub VPC
########################################

output "hub_vpc_id" {
    description = "ID of the hub VPC."
    value       = aws_vpc.hub.id
}

output "hub_private_subnet_ids" {
    description = "Map of AZ => subnet ID for hub private subnets."
    value       = { for az, s in aws_subnet.hub_private : az => s.id }
}

output "hub_public_subnet_ids" {
    description = "Map of AZ => subnet ID for hub public subnets (empty if none)."
    value       = { for az, s in aws_subnet.hub_public : az => s.id }
}

output "hub_igw_id" {
    description = "Internet Gateway ID for the hub (null if not created)."
    value       = length(aws_internet_gateway.hub) > 0 ? aws_internet_gateway.hub[0].id : null
}

output "hub_public_route_table_id" {
    description = "Route table ID used by hub public subnets (null if none)."
    value       = length(aws_route_table.hub_public) > 0 ? aws_route_table.hub_public[0].id : null
}

output "hub_private_route_table_ids" {
    description = "Map of AZ => route table ID for hub private subnets."
    value       = { for az, rt in aws_route_table.hub_private : az => rt.id }
}

output "hub_nat_gateway_ids" {
    description = "List of NAT Gateway IDs in the hub (empty if NAT not used)."
    value       = [for n in aws_nat_gateway.hub : n.id]
}

########################################
# Transit Gateway (optional)
########################################

output "tgw_id" {
    description = "Transit Gateway ID (null if TGW not created)."
    value       = length(aws_ec2_transit_gateway.this) > 0 ? aws_ec2_transit_gateway.this[0].id : null
}

output "tgw_attachment_hub_id" {
    description = "TGW attachment ID for the hub (null if TGW not created)."
    value       = length(aws_ec2_transit_gateway_vpc_attachment.hub) > 0 ? aws_ec2_transit_gateway_vpc_attachment.hub[0].id : null
}

output "tgw_attachment_spoke_ids" {
    description = "Map of spoke name => TGW attachment ID (empty if TGW not created)."
    value       = { for name, a in aws_ec2_transit_gateway_vpc_attachment.spoke : name => a.id }
}

########################################
# Spokes
########################################

output "spoke_vpc_ids" {
    description = "Map of spoke name => VPC ID."
    value       = { for name, v in aws_vpc.spoke : name => v.id }
}   

output "spoke_private_subnet_ids" {
    description = "Map of \"spoke|az\" => private subnet ID for all spokes."
    value       = { for key, s in aws_subnet.spoke_private : key => s.id }
}

output "spoke_public_subnet_ids" {
    description = "Map of \"spoke|az\" => public subnet ID for all spokes (empty where none)."
    value       = { for key, s in aws_subnet.spoke_public : key => s.id }
}

output "spoke_private_route_table_ids" {
    description = "Map of \"spoke|az\" => private route table ID for all spokes."
    value       = { for key, rt in aws_route_table.spoke_private : key => rt.id }
}

output "spoke_public_route_table_ids" {
    description = "Map of spoke name => public route table ID (only for spokes with IGW/public subnets)."
    value       = { for name, rt in aws_route_table.spoke_public : name => rt.id }
}

########################################
# VPC Flow Logs
########################################

output "flow_logs_destination_type" {
    description = "Where flow logs are sent: s3, cloudwatch, or disabled."
    value       = var.enable_vpc_flow_logs ? var.flow_logs_destination_type : "disabled"
}

output "flow_logs_s3_bucket" {
    description = "S3 bucket used for flow logs (null if not using S3)."
    value       = local.flow_to_s3 ? var.flow_logs_s3_bucket_name : null
}

output "flow_logs_log_group_name" {
    description = "CloudWatch Log Group name for flow logs (null if not using CloudWatch)."
    value       = length(aws_cloudwatch_log_group.flow_hub) > 0 ? aws_cloudwatch_log_group.flow_hub[0].name : null
}

output "flow_logs_iam_role_arn" {
    description = "IAM role ARN used by VPC Flow Logs for CloudWatch destination (null if not using CloudWatch)."
    value       = length(aws_iam_role.flowlogs_role) > 0 ? aws_iam_role.flowlogs_role[0].arn : null
}
