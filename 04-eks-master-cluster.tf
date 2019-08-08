resource "aws_eks_cluster" "eks" {
  name            = "${var.project_name}-${var.env}"
  role_arn        = "${aws_iam_role.iam_role.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.cluster.id}"]
    subnet_ids         = var.internal_subnet_ids
  }

  depends_on = [
    "aws_iam_role_policy_attachment.AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.AmazonEKSServicePolicy",
  ]
}
