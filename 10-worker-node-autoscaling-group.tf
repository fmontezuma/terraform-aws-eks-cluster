data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.eks.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
data "aws_region" "current" {
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace

cd /opt
sudo yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64 >> results.txt
curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O >> results.txt
unzip CloudWatchMonitoringScripts-1.2.2.zip && \
rm CloudWatchMonitoringScripts-1.2.2.zip && \
cd aws-scripts-mon >> results.txt
crontab -l | { cat; echo "*/1 * * * * /opt/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --disk-space-util --disk-path=/ --swap-util --auto-scaling --from-cron"; } | crontab -

/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks.certificate_authority[0].data}' '${var.project_name}-${var.env}'
USERDATA

}

resource "aws_ebs_encryption_by_default" "ebs_encryption" {
  enabled = true
}

resource "aws_launch_configuration" "launch_config" {
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.node.name
  image_id = data.aws_ami.eks-worker.id
  instance_type = "${var.instance_type}"
  name_prefix = "${var.project_name}-${var.env}"
  security_groups = [aws_security_group.node.id]
  user_data_base64 = base64encode(local.node-userdata)
  # key_name = "ireland-keypair"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  count = length(var.internal_subnet_ids)

  launch_configuration = aws_launch_configuration.launch_config.id
  min_size = var.asg_min_size
  max_size = var.asg_max_size  
  name = "${var.project_name}-${var.env}-${count.index + 1}"
  vpc_zone_identifier = [var.internal_subnet_ids[count.index]]
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  target_group_arns = [aws_lb_target_group.nlb_tg.arn]

  tag {
    key = "Name"
    value = "${var.project_name}-${var.env}-${count.index + 1}"
    propagate_at_launch = true
  }

  tag {
    key = "kubernetes.io/cluster/${var.project_name}-${var.env}"
    value = "owned"
    propagate_at_launch = true
  }

  tag {
    key = "k8s.io/cluster-autoscaler/enabled"
    value = ""
    propagate_at_launch = true
  }

  tag {
    key = "k8s.io/cluster-autoscaler/${var.project_name}-${var.env}"
    value = ""
    propagate_at_launch = true
  }

  provisioner "local-exec" {
    working_dir = path.module
    command = <<COMMAND
echo "${local.kubeconfig}" > ~/.kube/kubeconfig-${var.project_name}-${var.env}.yaml & \
echo "${local.config_map_aws_auth}" > aws_auth_configmap.yaml & \
kubectl apply -f aws_auth_configmap.yaml --kubeconfig ~/.kube/kubeconfig-${var.project_name}-${var.env}.yaml & \
rm aws_auth_configmap.yaml
COMMAND
  }
}
