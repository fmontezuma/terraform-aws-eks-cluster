resource "aws_iam_role" "iam_role_node" {
  name = "${var.project_name}-${var.env}-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.iam_role_node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.iam_role_node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.iam_role_node.name
}

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "cloudwatch-policy"
  role = aws_iam_role.iam_role_node.name
  policy = "${file("${path.module}/worker-node-iam-role-cloudwatch-policy.json")}"


resource "aws_iam_role_policy" "autoscaler_policy" {
  name = "autoscaler-policy"
  role = aws_iam_role.iam_role_node.name
  policy = "${file("${path.module}/worker-node-iam-role-autoscaler-policy.json")}"
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.project_name}-${var.env}"
  role = aws_iam_role.iam_role_node.name
}
