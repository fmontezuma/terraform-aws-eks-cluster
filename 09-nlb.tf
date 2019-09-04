resource "aws_lb" "nlb" {
  name               = "${var.project_name}-${var.env}"
  internal           = var.nlb_internal
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "nlb_tg" {
  name     = "${var.project_name}-${var.env}"
  port     = 30000
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.nlb_tg.arn}"
  }
}

resource "aws_lb_listener" "nlb_listener_https" {
  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.nlb_certificate_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.nlb_tg.arn}"
  }
}
