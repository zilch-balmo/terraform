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

  name   = "${var.name}"
  tier   = "backend"
  vpc_id = "${module.network.vpc_id}"
}

module "security" {
  source = "modules/security"

  name   = "${var.name}"
  vpc_id = "${module.network.vpc_id}"
}

# then create an RDS database that's accessible from the cluster security group
module "database" {
  source = "modules/database"

  name              = "${var.name}"
  security_group_id = "${module.security.database_security_group_id}"
  vpc_id            = "${module.network.vpc_id}"
}

# enable database administration via a lambda function
module "database-admin" {
  source = "modules/database-admin"

  name              = "${var.name}"
  security_group_id = "${module.security.backend_security_group_id}"
  vpc_id            = "${module.network.vpc_id}"
}

# then create the frontend
module "app" {
  source = "modules/app"

  ci_user_arn = "${module.ci.user_arn}"
  name        = "${var.name}"
  zone_id     = "${module.routing.zone_id}"
}

# then create an ECS service within the cluster (that can use the database)
module "backend" {
  source = "modules/backend"

  alb_security_group_id     = "${module.security.alb_security_group_id}"
  backend_security_group_id = "${module.security.backend_security_group_id}"
  cluster_id                = "${module.cluster.cluster_id}"
  database_host             = "${module.database.host}"
  execution_role_arn        = "${module.cluster.execution_role_arn}"
  name                      = "${var.name}"
  user_pool_arn             = "${module.auth.user_pool_arn}"
  user_pool_client_id       = "${module.auth.user_pool_backend_client_id}"
  user_pool_domain          = "${module.auth.user_pool_domain}"
  vpc_id                    = "${module.network.vpc_id}"
  zone_id                   = "${module.routing.zone_id}"
}

module "api" {
  source = "modules/api"

  name    = "${var.name}"
  vpc_id  = "${module.network.vpc_id}"
  zone_id = "${module.routing.zone_id}"
}
