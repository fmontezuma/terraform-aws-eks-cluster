output "kubeconfig" {
  value = local.kubeconfig
}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

output "nlb" {
  value = aws_lb.nlb
}
