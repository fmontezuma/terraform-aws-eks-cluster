variable project_name {}
variable env {}
variable instance_type {}
variable nlb_certificate_arn {}
variable vpc_id {}
variable internal_subnet_ids {}
variable public_subnet_ids {}
variable asg_min_size {}
variable asg_max_size {}
variable nlb_internal {}

variable "local_exec_interpreter" {
  description = "Command to run for local-exec resources. Must be a shell-style interpreter. If you are on Windows Git Bash is a good choice."
  type        = list(string)
  default     = ["bash", "-c"]
}

variable aws_profile_name {}