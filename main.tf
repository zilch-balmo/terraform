provider "aws" {
  profile             = "zilch"
  region              = "us-west-2"
  allowed_account_ids = ["534764804984"]
}

provider "aws" {
  profile             = "zilch"
  region              = "us-east-1"
  allowed_account_ids = ["534764804984"]
  alias               = "east"
}

terraform {
  backend "s3" {
    bucket  = "terraform.zilch.me"
    key     = "terraform"
    profile = "zilch"
    region  = "us-west-2"
  }
}

module "ci" {
  source = "modules/ci"
}

# first create a VPC network
module "network" {
  source = "modules/network"

  name = "${var.name}"
}

# and routing
module "routing" {
  source = "modules/routing"

  name   = "${var.name}"
  vpc_id = "${module.network.vpc_id}"
}

# and a user pool for authentication
module "auth" {
  source = "modules/auth"

  name    = "${var.name}"
  zone_id = "${module.routing.zone_id}"
}

# then create an ECS Fargate cluster within the network
module "cluster" {
  source = "modules/cluster"

  alb_security_group_id = "${module.routing.security_group_id}"
  name                  = "${var.name}"
  tier                  = "backend"
  vpc_id                = "${module.network.vpc_id}"
}

# then create an RDS database that's accessible from the cluster security group
module "database" {
  source = "modules/database"

  name   = "${var.name}"
  vpc_id = "${module.network.vpc_id}"

  allowed_security_group_ids = [
    "${module.cluster.security_group_id}",
  ]
}

# enable database administration via a lambda function
module "database-admin" {
  source = "modules/database-admin"

  name              = "${var.name}"
  security_group_id = "${module.cluster.security_group_id}"
  vpc_id            = "${module.network.vpc_id}"
}

# then create an ECS service within the cluster (that can use the database)
module "backend" {
  source = "modules/backend"

  alb_id              = "${module.routing.alb_id}"
  alb_dns_name        = "${module.routing.alb_dns_name}"
  alb_zone_id         = "${module.routing.alb_zone_id}"
  cluster_id          = "${module.cluster.cluster_id}"
  database_host       = "${module.database.host}"
  execution_role_arn  = "${module.cluster.execution_role_arn}"
  name                = "${var.name}"
  security_group_id   = "${module.cluster.security_group_id}"
  user_pool_arn       = "${module.auth.user_pool_arn}"
  user_pool_client_id = "${module.auth.user_pool_client_id}"
  user_pool_domain    = "${module.auth.user_pool_domain}"
  vpc_id              = "${module.network.vpc_id}"
  zone_id             = "${module.routing.zone_id}"
}
