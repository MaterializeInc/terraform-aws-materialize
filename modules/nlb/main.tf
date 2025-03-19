resource "aws_lb" "nlb" {
  name                             = var.name_prefix
  internal                         = var.internal
  load_balancer_type               = "network"
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
}

module "target_pgwire" {
  source = "./target"

  name              = "${var.name_prefix}-pgwire"
  nlb_arn           = aws_lb.nlb.arn
  namespace         = var.namespace
  vpc_id            = var.vpc_id
  port              = 6875
  service_name      = "mz${var.mz_resource_id}-balancerd"
  health_check_path = "/api/readyz"
}

module "target_http" {
  source = "./target"

  name              = "${var.name_prefix}-http"
  nlb_arn           = aws_lb.nlb.arn
  namespace         = var.namespace
  vpc_id            = var.vpc_id
  port              = 6876
  service_name      = "mz${var.mz_resource_id}-balancerd"
  health_check_path = "/api/readyz"
}

module "target_console" {
  source = "./target"

  name              = "${var.name_prefix}-console"
  nlb_arn           = aws_lb.nlb.arn
  namespace         = var.namespace
  vpc_id            = var.vpc_id
  port              = 8080
  service_name      = "mz${var.mz_resource_id}-console"
  health_check_path = "/"
}
