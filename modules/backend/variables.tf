variable "alb_id" {}
variable "cluster_id" {}
variable "execution_role_arn" {}

variable "fargate_cpu" {
  default = 256
}

variable "fargate_memory" {
  default = 512
}

variable "name" {}
variable "security_group_id" {}
variable "vpc_id" {}
