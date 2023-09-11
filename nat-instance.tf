
module "nat_instance_label" {
  source  = "git::https://github.com/jon-butterworth/tf-module-null-label"

  attributes = ["nat", "instance"]

  context = module.this.context
}

resource "aws_security_group" "nat_instance" {
  count = local.nat_instance_enabled ? 1 : 0

  name        = module.nat_instance_label.id
  description = "Security Group for NAT Instance"
  vpc_id      = local.vpc_id
  tags        = module.nat_instance_label.tags
}

resource "aws_security_group_rule" "nat_instance_egress" {
  count = local.nat_instance_enabled ? 1 : 0

  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
  security_group_id = join("", aws_security_group.nat_instance[*].id)
  type              = "egress"
}

resource "aws_security_group_rule" "nat_instance_ingress" {
  count = local.nat_instance_enabled ? 1 : 0

  description       = "Allow ingress traffic from the VPC CIDR block"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [local.base_ipv4_cidr_block]
  security_group_id = join("", aws_security_group.nat_instance[*].id)
  type              = "ingress"
}

data "aws_ami" "nat_instance" {
  count = local.need_nat_ami_id ? 1 : 0

  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-comparison.html
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html
# https://dzone.com/articles/nat-instance-vs-nat-gateway
resource "aws_instance" "nat_instance" {
  count = local.nat_instance_enabled ? local.nat_count : 0

  ami                    = local.nat_instance_ami_id
  instance_type          = var.nat_instance_type
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.nat_instance[0].id]

  tags = merge(
    module.nat_instance_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_instance_label.id, local.delimiter, local.subnet_az_abbreviations[count.index])
    }
  )

  # Required by NAT
  # https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html#EIP_Disable_SrcDestCheck
  source_dest_check = false

  associate_public_ip_address = true #tfsec:ignore:AWS012

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint_enabled ? "enabled" : "disabled"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_tokens                 = var.metadata_http_tokens_required ? "required" : "optional"
  }

  root_block_device {
    encrypted = local.nat_instance_root_block_device_encrypted
  }

  dynamic "credit_specification" {
    for_each = var.nat_instance_cpu_credits_override == "" ? [] : [var.nat_instance_cpu_credits_override]

    content {
      cpu_credits = var.nat_instance_cpu_credits_override
    }
  }

  ebs_optimized = true
}

resource "aws_eip_association" "nat_instance" {
  count = local.nat_instance_enabled ? local.nat_count : 0

  instance_id   = aws_instance.nat_instance[count.index].id
  allocation_id = local.nat_eip_allocations[count.index]
}

resource "aws_route" "nat_instance" {
  count = local.nat_instance_enabled ? local.private_route_table_count : 0

  route_table_id         = local.private_route_table_ids[count.index]
  network_interface_id   = element(aws_instance.nat_instance[*].primary_network_interface_id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.private]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}
