# ---------------------------------------------------------------
# Network lookups. Nothing is read from the network stack's state:
# every component is found by its tags.
# ---------------------------------------------------------------

data "aws_vpc" "main" {
  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier    = "public"
    Project = var.project_name
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier    = "private"
    Project = var.project_name
  }
}

# Read each subnet so they can be ordered by AZ (aws_subnets returns IDs in no fixed order).
data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

# Latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  public_subnets_by_az = [
    for s in sort([for s in data.aws_subnet.public : "${s.availability_zone}|${s.id}"]) :
    split("|", s)[1]
  ]
  private_subnets_by_az = [
    for s in sort([for s in data.aws_subnet.private : "${s.availability_zone}|${s.id}"]) :
    split("|", s)[1]
  ]
  instance_subnet_id = local.public_subnets_by_az[var.subnet_index]
  # Same AZ as the web instance, so web -> redis traffic stays in one AZ.
  redis_subnet_id = local.private_subnets_by_az[var.subnet_index]
}
