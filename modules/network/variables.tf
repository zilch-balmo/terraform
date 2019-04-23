variable "ami_name_pattern" {
  default = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

variable "ami_publisher" {
  default = "099720109477" # Canonical
}

variable "cidr_block" {
  default = "10.10.0.0/16"
}

variable "name" {}
