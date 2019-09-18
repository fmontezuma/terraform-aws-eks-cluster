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

  provisioner "local-exec" {
    working_dir = path.module
    command = <<COMMAND
echo "${local.kubeconfig}" > ~/.kube/kubeconfig-${var.project_name}-${var.env}.yaml & \
echo "${local.config_map_aws_auth}" > aws_auth_configmap.yaml & \
kubectl apply -f aws_auth_configmap.yaml --kubeconfig ~/.kube/kubeconfig-${var.project_name}-${var.env}.yaml & \
rm aws_auth_configmap.yaml;
COMMAND
  }
}
