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

resource "aws_launch_configuration" "launch_config" {
  associate_public_ip_address = false
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
  count = length(var.subnets)

  desired_capacity = 1
  launch_configuration = aws_launch_configuration.launch_config.id
  max_size = 6
  min_size = 1
  name = "${var.project_name}-${var.env}-${count.index + 1}"
  vpc_zone_identifier = [aws_subnet.subnet[count.index].id]
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
}
