locals {
  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks.certificate_authority.0.data}
  name: ${var.project_name}-${var.env}
contexts:
- context:
    cluster: ${var.project_name}-${var.env}
    user: ${var.project_name}-${var.env}
  name: ${var.project_name}-${var.env}
current-context: ${var.project_name}-${var.env}
kind: Config
preferences: {}
users:
- name: ${var.project_name}-${var.env}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.project_name}-${var.env}"
KUBECONFIG
}
