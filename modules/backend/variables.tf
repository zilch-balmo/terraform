variable "alb_security_group_id" {}
variable "backend_security_group_id" {}
variable "cluster_id" {}
variable "database_host" {}
variable "execution_role_arn" {}

variable "fargate_cpu" {
  default = 256
}

variable "fargate_memory" {
  default = 512
}

variable "name" {}
variable "user_pool_arn" {}
variable "user_pool_client_id" {}
variable "user_pool_domain" {}
variable "vpc_id" {}
variable "zone_id" {}
