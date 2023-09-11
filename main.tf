locals {
  enabled = module.this.enabled && (var.public_subnets_enabled || var.private_subnets_enabled) && (var.ipv4_enabled || var.ipv6_enabled)

  e = local.enabled

  delimiter = module.this.delimiter

  nat64_cidr = "64:ff9b::/96"

  vpc_id = var.vpc_id

  use_az_ids = local.e && length(var.availability_zone_ids) > 0
  use_az_var = local.e && length(var.availability_zones) > 0
  az_id_map   = try(zipmap(data.aws_availability_zones.default[0].zone_ids, data.aws_availability_zones.default[0].names), {})
  az_name_map = try(zipmap(data.aws_availability_zones.default[0].names, data.aws_availability_zones.default[0].zone_ids), {})

  az_option_map = {
    from_az_ids = local.e ? [for id in var.availability_zone_ids : local.az_id_map[id]] : []
    from_az_var = local.e ? var.availability_zones : []
    all_azs     = local.e ? sort(data.aws_availability_zones.default[0].names) : []
  }

  subnet_availability_zone_option = local.use_az_ids ? "from_az_ids" : (
    local.use_az_var ? "from_az_var" : "all_azs"
  )

  subnet_possible_availability_zones = local.az_option_map[local.subnet_availability_zone_option]

  vpc_availability_zones = (
    var.max_subnet_count == 0 || var.max_subnet_count >= length(local.subnet_possible_availability_zones)
    ) ? (
    local.subnet_possible_availability_zones
  ) : slice(local.subnet_possible_availability_zones, 0, var.max_subnet_count)


  subnet_availability_zones = flatten([for z in local.vpc_availability_zones : [for net in range(0, var.subnets_per_az_count) : z]])

  subnet_az_count = local.e ? length(local.subnet_availability_zones) : 0

  az_abbreviation_map_map = {
    short = "to_short"
    fixed = "to_fixed"
    full  = "identity"
  }

  az_abbreviation_map = module.utils.region_az_alt_code_maps[local.az_abbreviation_map_map[var.availability_zone_attribute_style]]

  subnet_az_abbreviations = [for az in local.subnet_availability_zones : local.az_abbreviation_map[az]]

  existing_az_count         = local.e ? length(data.aws_availability_zones.default[0].names) : 0
  base_cidr_reservations    = (var.max_subnet_count == 0 ? local.existing_az_count : var.max_subnet_count) * var.subnets_per_az_count
  private_cidr_reservations = (local.private_enabled ? 1 : 0) * local.base_cidr_reservations
  public_cidr_reservations  = (local.public_enabled ? 1 : 0) * local.base_cidr_reservations
  cidr_reservations         = local.private_cidr_reservations + local.public_cidr_reservations


  required_ipv4_subnet_bits = local.e ? ceil(log(local.cidr_reservations, 2)) : 1
  required_ipv6_subnet_bits = 8 # Currently the only value allowed by AWS

  supplied_ipv4_private_subnet_cidrs = try(var.ipv4_cidrs[0].private, [])
  supplied_ipv4_public_subnet_cidrs  = try(var.ipv4_cidrs[0].public, [])

  supplied_ipv6_private_subnet_cidrs = try(var.ipv6_cidrs[0].private, [])
  supplied_ipv6_public_subnet_cidrs  = try(var.ipv6_cidrs[0].public, [])

  compute_ipv4_cidrs = local.ipv4_enabled && (length(local.supplied_ipv4_private_subnet_cidrs) + length(local.supplied_ipv4_public_subnet_cidrs)) == 0
  compute_ipv6_cidrs = local.ipv6_enabled && (length(local.supplied_ipv6_private_subnet_cidrs) + length(local.supplied_ipv6_public_subnet_cidrs)) == 0
  need_vpc_data      = (local.compute_ipv4_cidrs && length(var.ipv4_cidr_block) == 0) || (local.compute_ipv6_cidrs && length(var.ipv6_cidr_block) == 0)

  base_ipv4_cidr_block = length(var.ipv4_cidr_block) > 0 ? var.ipv4_cidr_block[0] : (local.need_vpc_data ? data.aws_vpc.default[0].cidr_block : "")
  base_ipv6_cidr_block = length(var.ipv6_cidr_block) > 0 ? var.ipv6_cidr_block[0] : (local.need_vpc_data ? data.aws_vpc.default[0].ipv6_cidr_block : "")

  ipv4_private_subnet_cidrs = local.compute_ipv4_cidrs ? [
    for net in range(0, local.private_cidr_reservations) : cidrsubnet(local.base_ipv4_cidr_block, local.required_ipv4_subnet_bits, net)
  ] : local.supplied_ipv4_private_subnet_cidrs

  ipv4_public_subnet_cidrs = local.compute_ipv4_cidrs ? [
    for net in range(local.private_cidr_reservations, local.cidr_reservations) : cidrsubnet(local.base_ipv4_cidr_block, local.required_ipv4_subnet_bits, net)
  ] : local.supplied_ipv4_public_subnet_cidrs

  ipv6_private_subnet_cidrs = local.compute_ipv6_cidrs ? [
    for net in range(0, local.private_cidr_reservations) : cidrsubnet(local.base_ipv6_cidr_block, local.required_ipv6_subnet_bits, net)
  ] : local.supplied_ipv6_private_subnet_cidrs

  ipv6_public_subnet_cidrs = local.compute_ipv6_cidrs ? [
    for net in range(local.private_cidr_reservations, local.cidr_reservations) : cidrsubnet(local.base_ipv6_cidr_block, local.required_ipv6_subnet_bits, net)
  ] : local.supplied_ipv6_public_subnet_cidrs

  public_enabled  = local.e && var.public_subnets_enabled
  private_enabled = local.e && var.private_subnets_enabled
  ipv4_enabled    = local.e && var.ipv4_enabled
  ipv6_enabled    = local.e && var.ipv6_enabled

  igw_configured = length(var.igw_id) > 0
  ipv6_egress_only_configured = local.ipv6_enabled && length(var.ipv6_egress_only_igw_id) > 0

  public4_enabled  = local.public_enabled && local.ipv4_enabled
  public6_enabled  = local.public_enabled && local.ipv6_enabled
  private4_enabled = local.private_enabled && local.ipv4_enabled
  private6_enabled = local.private_enabled && local.ipv6_enabled

  public_dns64_enabled = local.public6_enabled && var.public_dns64_nat64_enabled
  private_dns64_enabled = local.private6_enabled && (
    var.private_dns64_nat64_enabled == null ? local.public4_enabled : var.private_dns64_nat64_enabled
  )

  public_route_table_enabled = local.public_enabled && var.public_route_table_enabled

  public_route_table_count = coalesce(
    local.public_enabled ? null : 0,
    length(var.public_route_table_ids) == 0 ? null : length(var.public_route_table_ids),
    var.public_route_table_enabled ? null : 0,
    var.public_route_table_per_subnet_enabled == true ? local.subnet_az_count : null,
    var.public_route_table_per_subnet_enabled == false ? 1 : null,
    local.public_dns64_enabled ? local.subnet_az_count : 1
  )

  create_public_route_tables = local.public_route_table_enabled && length(var.public_route_table_ids) == 0
  public_route_table_ids     = local.create_public_route_tables ? aws_route_table.public[*].id : var.public_route_table_ids

  private_route_table_enabled = local.private_enabled && var.private_route_table_enabled
  private_route_table_count   = local.private_route_table_enabled ? local.subnet_az_count : 0
  private_route_table_ids     = local.private_route_table_enabled ? aws_route_table.private[*].id : []

  public_open_network_acl_enabled = local.public_enabled && var.public_open_network_acl_enabled
  private_open_network_acl_enabled = local.private_enabled && var.private_open_network_acl_enabled

  nat_instance_useful = local.private4_enabled
  nat_gateway_useful  = local.nat_instance_useful || local.public_dns64_enabled || local.private_dns64_enabled
  nat_count           = min(local.subnet_az_count, var.max_nats)

  nat_gateway_setting = var.nat_instance_enabled == true ? var.nat_gateway_enabled == true : !(
    var.nat_gateway_enabled == false # not true or null
  )
  nat_instance_setting = local.nat_gateway_setting ? false : var.nat_instance_enabled == true # not false or null

  nat_gateway_enabled  = local.nat_gateway_useful && local.nat_gateway_setting
  nat_instance_enabled = local.nat_instance_useful && local.nat_instance_setting
  nat_enabled          = local.nat_gateway_enabled || local.nat_instance_enabled
  need_nat_eips        = local.nat_enabled && length(var.nat_elastic_ips) == 0
  need_nat_eip_data    = local.nat_enabled && length(var.nat_elastic_ips) > 0
  nat_eip_allocations  = local.nat_enabled ? (local.need_nat_eips ? aws_eip.default[*].id : data.aws_eip.nat[*].id) : []

  need_nat_ami_id     = local.nat_instance_enabled && length(var.nat_instance_ami_id) == 0
  nat_instance_ami_id = local.need_nat_ami_id ? data.aws_ami.nat_instance[0].id : try(var.nat_instance_ami_id[0], "")

  az_private_subnets_map = { for z in local.vpc_availability_zones : z => (
    [for s in aws_subnet.private : s.id if s.availability_zone == z])
  }

  az_public_subnets_map = { for z in local.vpc_availability_zones : z => (
    [for s in aws_subnet.public : s.id if s.availability_zone == z])
  }

  az_private_route_table_ids_map = { for k, v in local.az_private_subnets_map : k => (
    [for t in aws_route_table_association.private : t.route_table_id if contains(v, t.subnet_id)])
  }

  az_public_route_table_ids_map = { for k, v in local.az_public_subnets_map : k => (
    [for t in aws_route_table_association.public : t.route_table_id if contains(v, t.subnet_id)])
  }

  named_private_subnets_map = { for i, s in var.subnets_per_az_names : s => (
    compact([for k, v in local.az_private_subnets_map : try(v[i], "")]))
  }

  named_public_subnets_map = { for i, s in var.subnets_per_az_names : s => (
    compact([for k, v in local.az_public_subnets_map : try(v[i], "")]))
  }

  named_private_route_table_ids_map = { for i, s in var.subnets_per_az_names : s => (
    compact([for k, v in local.az_private_route_table_ids_map : try(v[i], "")]))
  }

  named_public_route_table_ids_map = { for i, s in var.subnets_per_az_names : s => (
    compact([for k, v in local.az_public_route_table_ids_map : try(v[i], "")]))
  }

  named_private_subnets_stats_map = { for i, s in var.subnets_per_az_names : s => (
    [
      for k, v in local.az_private_route_table_ids_map : {
        az             = k
        route_table_id = try(v[i], "")
        subnet_id      = try(local.az_private_subnets_map[k][i], "")
      }
    ])
  }

  named_public_subnets_stats_map = { for i, s in var.subnets_per_az_names : s => (
    [
      for k, v in local.az_public_route_table_ids_map : {
        az             = k
        route_table_id = try(v[i], "")
        subnet_id      = try(local.az_public_subnets_map[k][i], "")
      }
    ])
  }
}

data "aws_availability_zones" "default" {
  count = local.enabled ? 1 : 0

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_vpc" "default" {
  count = local.need_vpc_data ? 1 : 0

  id = local.vpc_id
}

data "aws_eip" "nat" {
  count = local.need_nat_eip_data ? length(var.nat_elastic_ips) : 0

  public_ip = element(var.nat_elastic_ips, count.index)
}

resource "aws_eip" "default" {
  count = local.need_nat_eips ? local.nat_count : 0

  tags = merge(
    module.nat_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_label.id, local.delimiter, local.subnet_az_abbreviations[count.index])
    }
  )

  lifecycle {
    create_before_destroy = true
  }
  #bridgecrew:skip=BC_AWS_NETWORKING_48: Skipping requirement for EIPs to be attached to EC2 instances because we are attaching to NAT Gateway.
}

module "utils" {
  source  = "cloudposse/utils/aws"
  version = "1.3.0"
}
