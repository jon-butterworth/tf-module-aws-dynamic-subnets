output "availability_zones" {
  value       = local.vpc_availability_zones
}

output "availability_zone_ids" {
  value = local.use_az_ids ? var.availability_zone_ids : [
    for az in local.vpc_availability_zones : local.az_name_map[az]
  ]
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  value       = aws_subnet.public[*].arn
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  value       = aws_subnet.private[*].arn
}

output "public_subnet_cidrs" {
  value       = local.public4_enabled ? aws_subnet.public[*].cidr_block : []
}

output "public_subnet_ipv6_cidrs" {
  value       = local.public6_enabled ? aws_subnet.public[*].ipv6_cidr_block : []
}

output "private_subnet_cidrs" {
  value       = local.private4_enabled ? aws_subnet.private[*].cidr_block : []
}

output "private_subnet_ipv6_cidrs" {
  value       = local.private6_enabled ? aws_subnet.private[*].ipv6_cidr_block : []
}

output "public_route_table_ids" {
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  value       = aws_route_table.private[*].id
}

output "public_network_acl_id" {
  value       = local.public_open_network_acl_enabled ? aws_network_acl.public[0].id : null
}

output "private_network_acl_id" {
  value       = local.private_open_network_acl_enabled ? aws_network_acl.private[0].id : null
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.default[*].id
}

output "nat_instance_ids" {
  value       = aws_instance.nat_instance[*].id
}

output "nat_instance_ami_id" {
  value       = local.nat_instance_enabled ? local.nat_instance_ami_id : null
}

output "nat_ips" {
  value       = local.need_nat_eip_data ? var.nat_elastic_ips : aws_eip.default[*].public_ip
}

output "nat_eip_allocation_ids" {
  value       = local.nat_eip_allocations
}

output "az_private_subnets_map" {
  value       = local.az_private_subnets_map
}

output "az_public_subnets_map" {
  value       = local.az_public_subnets_map
}

output "az_private_route_table_ids_map" {
  value       = local.az_private_route_table_ids_map
}

output "az_public_route_table_ids_map" {
  value       = local.az_public_route_table_ids_map
}

output "named_private_subnets_map" {
  value       = local.named_private_subnets_map
}

output "named_public_subnets_map" {
  value       = local.named_public_subnets_map
}

output "named_private_route_table_ids_map" {
  value       = local.named_private_route_table_ids_map
}

output "named_public_route_table_ids_map" {
  value       = local.named_public_route_table_ids_map
}

output "named_private_subnets_stats_map" {
  value       = local.named_private_subnets_stats_map
}

output "named_public_subnets_stats_map" {
  value       = local.named_public_subnets_stats_map
}
