resource "aws_ecr_repository" "repository" {
  name         = var.ecr_repository_name
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
}