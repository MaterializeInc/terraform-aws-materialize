resource "aws_lb_target_group" "target_group" {
  name               = var.name
  port               = var.port
  preserve_client_ip = true
  protocol           = "TCP"
  target_type        = "ip"
  vpc_id             = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = var.health_check_protocol
    port                = 8080
    path                = var.health_check_path
    matcher             = "200"
    timeout             = 10
  }

  stickiness {
    enabled = true
    type    = "source_ip"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = var.nlb_arn
  port              = var.port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "kubernetes_manifest" "target_group_binding" {
  manifest = {
    "apiVersion" = "elbv2.k8s.aws/v1beta1"
    "kind"       = "TargetGroupBinding"
    "metadata" = {
      "name"      = var.name
      "namespace" = var.namespace
    }
    "spec" = {
      "serviceRef" = {
        "name" = var.service_name
        "port" = var.port
      }
      "targetGroupARN" = aws_lb_target_group.target_group.arn
    }
  }

  lifecycle {
    ignore_changes = [
      manifest.spec.serviceRef.name,
    ]
  }

  depends_on = [
    aws_lb_listener.listener,
    aws_lb_target_group.target_group,
  ]
}
