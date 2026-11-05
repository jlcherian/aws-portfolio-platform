module "network" {
  source   = "../../modules/network"
  name     = "portfolio-dev"
  vpc_cidr = "10.0.0.0/16"
}

module "compute" {
  source             = "../../modules/compute"
  name               = "portfolio-dev"
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
}

module "database" {
  source             = "../../modules/database"
  name               = "portfolio-dev"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  web_sg_id          = module.compute.web_sg_id
}