variable "vpc_id" {
  type        = string
}

variable "igw_id" {
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.igw_id) < 2
    error_message = "Only 1 igw_id can be provided."
  }
}

variable "ipv6_egress_only_igw_id" {
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv6_egress_only_igw_id) < 2
    error_message = "Only 1 ipv6_egress_only_igw_id can be provided."
  }
}

variable "max_subnet_count" {
  type        = number
  default     = 0
  nullable    = false
}

variable "max_nats" {
  type        = number
  default  = 999
  nullable = false
}

variable "private_subnets_enabled" {
  type        = bool
  default     = true
  nullable    = false
}

variable "public_subnets_enabled" {
  type        = bool
  default     = true
  nullable    = false
}

variable "private_label" {
  type        = string
  default     = "private"
  nullable    = false
}

variable "public_label" {
  type        = string
  description = "The string to use in IDs and elsewhere to identify resources for the public subnets and distinguish them from resources for the private subnets"
  default     = "public"
  nullable    = false
}

variable "ipv4_enabled" {
  type        = bool
  description = "Set `true` to enable IPv4 addresses in the subnets"
  default     = true
  nullable    = false
}

variable "ipv6_enabled" {
  type        = bool
  description = "Set `true` to enable IPv6 addresses in the subnets"
  default     = false
  nullable    = false
}

variable "ipv4_cidr_block" {
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv4_cidr_block) < 2
    error_message = "Only 1 ipv4_cidr_block can be provided. Use ipv4_cidrs to provide a CIDR per subnet."
  }
}

variable "ipv6_cidr_block" {
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv6_cidr_block) < 2
    error_message = "Only 1 ipv6_cidr_block can be provided. Use ipv6_cidrs to provide a CIDR per subnet."
  }
}

variable "ipv4_cidrs" {
  type = list(object({
    private = list(string)
    public  = list(string)
  }))
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv4_cidrs) < 2
    error_message = "Only 1 ipv4_cidrs object can be provided. Lists of CIDRs are passed via the `public` and `private` attributes of the single object."
  }
}

variable "ipv6_cidrs" {
  type = list(object({
    private = list(string)
    public  = list(string)
  }))
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv6_cidrs) < 2
    error_message = "Only 1 ipv6_cidrs object can be provided. Lists of CIDRs are passed via the `public` and `private` attributes of the single object."
  }
}

variable "availability_zones" {
  type        = list(string)
  default     = []
  nullable    = false
}

variable "availability_zone_ids" {
  type        = list(string)
  default     = []
  nullable    = false
}

variable "availability_zone_attribute_style" {
  type        = string
  default     = "short"
  nullable    = false
}

variable "nat_gateway_enabled" {
  type        = bool
  default     = null
}

variable "nat_instance_enabled" {
  type        = bool
  default     = null
}

variable "nat_elastic_ips" {
  type        = list(string)
  default     = []
  nullable    = false
}

variable "map_public_ip_on_launch" {
  type        = bool
  default     = true
  nullable    = false
}

variable "private_assign_ipv6_address_on_creation" {
  type        = bool
  default     = true
  nullable    = false
}

variable "public_assign_ipv6_address_on_creation" {
  type        = bool
  default     = true
  nullable    = false
}

variable "private_dns64_nat64_enabled" {
  type        = bool
  default     = null
}

variable "public_dns64_nat64_enabled" {
  type        = bool
  default     = false
  nullable    = false
}

variable "ipv4_private_instance_hostname_type" {
  type        = string
  default     = "ip-name"
  nullable    = false
}

variable "ipv4_private_instance_hostnames_enabled" {
  type        = bool
  default     = false
  nullable    = false
}

variable "ipv6_private_instance_hostnames_enabled" {
  type        = bool
  default     = false
  nullable    = false
}

variable "ipv4_public_instance_hostname_type" {
  type        = string
  default     = "ip-name"
  nullable    = false
}

variable "ipv4_public_instance_hostnames_enabled" {
  type        = bool
  default     = false
  nullable    = false
}

variable "ipv6_public_instance_hostnames_enabled" {
  type        = bool
  default     = false
  nullable    = false
}

variable "private_open_network_acl_enabled" {
  type        = bool
  default     = true
  nullable    = false
}

variable "public_open_network_acl_enabled" {
  type        = bool
  default     = true
  nullable    = false
}

variable "open_network_acl_ipv4_rule_number" {
  type        = number
  default     = 100
  nullable    = false
}

variable "open_network_acl_ipv6_rule_number" {
  type        = number
  default     = 111
  nullable    = false
}

variable "private_route_table_enabled" {
  type        = bool
  default     = true
  nullable    = false
}

variable "public_route_table_ids" {
  type        = list(string)
  default     = []
  nullable    = false
}

variable "public_route_table_enabled" {
  type        = bool
  default     = true
  nullable    = false
}

variable "public_route_table_per_subnet_enabled" {
  type        = bool
  default     = null
}

variable "route_create_timeout" {
  type        = string
  default     = null
}
locals { route_create_timeout = var.aws_route_create_timeout == null ? var.route_create_timeout : var.aws_route_create_timeout }

variable "route_delete_timeout" {
  type        = string
  default     = null
}
locals { route_delete_timeout = var.aws_route_delete_timeout == null ? var.route_delete_timeout : var.aws_route_delete_timeout }

variable "subnet_create_timeout" {
  type        = string
  default = null
}

variable "subnet_delete_timeout" {
  type        = string
  default = null
}

variable "private_subnets_additional_tags" {
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "public_subnets_additional_tags" {
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "subnets_per_az_count" {
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition = var.subnets_per_az_count > 0
    error_message = "The `subnets_per_az` value must be greater than 0."
  }
}

variable "subnets_per_az_names" {
  type = list(string)
  default     = ["common"]
  nullable    = false
}

variable "nat_instance_type" {
  type        = string
  description = "NAT Instance type"
  default     = "t3.micro"
  nullable    = false
}

variable "nat_instance_ami_id" {
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.nat_instance_ami_id) < 2
    error_message = "Only 1 NAT Instance AMI ID can be provided."
  }
}

variable "nat_instance_cpu_credits_override" {
  type        = string
  default     = ""
  nullable    = false
  validation {
    condition = contains(["standard", "unlimited", ""], var.nat_instance_cpu_credits_override)
    error_message = "The `nat_instance_cpu_credits_override` value must be either \"standard\", \"unlimited\", or empty string."
  }
}

variable "metadata_http_endpoint_enabled" {
  type        = bool
  default     = true
  nullable    = false
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  default     = 1
  nullable    = false
}

variable "metadata_http_tokens_required" {
  type        = bool
  default     = true
  nullable    = false
}

variable "nat_instance_root_block_device_encrypted" {
  type        = bool
  default     = true
  nullable    = false
}
locals { nat_instance_root_block_device_encrypted = var.root_block_device_encrypted == null ? var.nat_instance_root_block_device_encrypted : var.root_block_device_encrypted }
