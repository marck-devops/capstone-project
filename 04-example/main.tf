module "network" {
  source = "../modules/network"

  name                       = var.project_name
  vpc_cidr                   = var.vpc_cidr
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_subnet_cidrs       = var.private_subnet_cidrs
  enable_nat_gateway         = var.enable_nat_gateway
  enable_s3_gateway_endpoint = var.enable_s3_gateway_endpoint
  enable_ssm_endpoints       = var.enable_ssm_endpoints
}

module "security_groups" {
  source = "../modules/security_groups"

  name             = var.project_name
  vpc_id           = module.network.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
  app_port         = var.app_port
}

# Role + instance profile with AmazonSSMManagedInstanceCore for the redis box.
module "redis_iam" {
  source = "../modules/iam"

  name        = var.project_name
  role_suffix = "redis-ssm"
}

module "compute" {
  source = "../modules/compute"

  name          = var.project_name
  instance_type = var.instance_type
  app_port      = var.app_port

  # Same AZ for both, so web -> redis traffic stays in one AZ.
  web_subnet_id   = module.network.public_subnet_ids[var.subnet_index]
  redis_subnet_id = module.network.private_subnet_ids[var.subnet_index]
  web_sg_id       = module.security_groups.web_sg_id
  redis_sg_id     = module.security_groups.redis_sg_id

  redis_iam_instance_profile = module.redis_iam.instance_profile_name

  create_key_pair           = var.create_key_pair
  private_key_output_dir    = path.root
  existing_key_name         = var.existing_key_name
  existing_private_key_path = var.existing_private_key_path

  # Redis installs packages during setup, so it waits for these.
  private_egress_ids = module.network.private_egress_ids
}
