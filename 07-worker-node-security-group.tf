resource "aws_security_group" "node" {
  name        = "${var.project_name}-${var.env}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.project_name}-${var.env}-node"
    "kubernetes.io/cluster/${var.project_name}-${var.env}" = "owned"
  }
}

resource "aws_security_group_rule" "node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nlb-k8s-node" {
  description              = "Allow NLB to access Ingress"
  from_port                = 30000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  cidr_blocks              = ["${var.vpc_cidr}"]
  to_port                  = 30000
  type                     = "ingress"
}
