resource "aws_ecs_cluster" "cluster" {
  provider = aws.west

  name = var.name
}

