resource "aws_lb" "nlb" {
  name               = var.name_prefix
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnet_ids
}

module "target_pgwire" {
  source = "./target"

  name              = "pgwire"
  nlb_arn           = aws_lb.nlb.arn
  namespace         = var.namespace
  vpc_id            = var.vpc_id
  port              = 6875
  service_name      = "mz${var.mz_resource_id}-balancerd"
  health_check_path = "/api/readyz"
}

module "target_http" {
  source = "./target"

  name              = "http"
  nlb_arn           = aws_lb.nlb.arn
  namespace         = var.namespace
  vpc_id            = var.vpc_id
  port              = 6876
  service_name      = "mz${var.mz_resource_id}-balancerd"
  health_check_path = "/api/readyz"
}

module "target_console" {
  source = "./target"

  name              = "console"
  nlb_arn           = aws_lb.nlb.arn
  namespace         = var.namespace
  vpc_id            = var.vpc_id
  port              = 8080
  service_name      = "mz${var.mz_resource_id}-console"
  health_check_path = "/"
}
