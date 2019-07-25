resource "aws_lb" "nlb" {
  name               = "${var.project_name}-${var.env}"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.subnet[*].id
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "nlb_tg" {
  name     = "${var.project_name}-${var.env}"
  port     = 30000
  protocol = "TCP"
  vpc_id   = "${aws_vpc.vpc.id}"
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

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = "${aws_lb.nlb.arn}"
  port              = "443"
  protocol          = "TCP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.nlb_tg.arn}"
  }
}
