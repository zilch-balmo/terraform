variable "alb_id" {}
variable "alb_dns_name" {}
variable "alb_zone_id" {}
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
variable "security_group_id" {}
variable "user_pool_arn" {}
variable "user_pool_client_id" {}
variable "user_pool_domain" {}
variable "vpc_id" {}
variable "zone_id" {}
