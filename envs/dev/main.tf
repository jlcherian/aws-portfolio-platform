module "network" {
  source   = "../../modules/network"
  name     = "portfolio-dev"
  vpc_cidr = "10.0.0.0/16"
}

module "certificate" {
  source      = "../../modules/certificate"
  zone_name   = "cloudpfbuildguide.click"
  domain_name = "app.cloudpfbuildguide.click"
}

module "compute" {
  source             = "../../modules/compute"
  name               = "portfolio-dev"
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  certificate_arn    = module.certificate.certificate_arn
}

module "database" {
  source             = "../../modules/database"
  name               = "portfolio-dev"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  web_sg_id          = module.compute.web_sg_id
}

module "ecs" {
  source             = "../../modules/ecs"
  name               = "portfolio-dev"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  alb_sg_id          = module.compute.alb_sg_id
  listener_arn       = module.compute.listener_arn
  image              = "558158825841.dkr.ecr.us-east-1.amazonaws.com/portfolio-app:latest"
}

resource "aws_route53_record" "app" {
  zone_id = module.certificate.zone_id
  name    = "app.cloudpfbuildguide.click"
  type    = "A"

  alias {
    name                   = module.compute.alb_dns_name
    zone_id                = module.compute.alb_zone_id
    evaluate_target_health = true
  }
}