data "aws_caller_identity" "current" {}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.iam_role_node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kubectl
      username: build
      groups:
        - system:masters
CONFIGMAPAWSAUTH

}

resource "null_resource" "create_config_map_aws_auth_kubeconfig" {
  provisioner "local-exec" {
    working_dir = path.module
    interpreter = var.local_exec_interpreter
    environment = {
      AWS_PROFILE = var.aws_profile_name
    }
    command = <<COMMAND
echo '${local.config_map_aws_auth}' > aws_auth_configmap.yaml && 
echo '${local.kubeconfig}' > kubeconfig-${var.project_name}-${var.env}.yaml && 
kubectl apply -f aws_auth_configmap.yaml --kubeconfig kubeconfig-${var.project_name}-${var.env}.yaml;
COMMAND
  }

  triggers = {
    eks_endpoint = aws_eks_cluster.eks.endpoint
  }
}