output "user_pool_arn" {
  value = aws_cognito_user_pool.pool.arn
}

output "user_pool_app_client_id" {
  value = aws_cognito_user_pool_client.app.id
}

/*
output "user_pool_backend_client_id" {
  value = "${aws_cognito_user_pool_client.backend.id}"
}
*/

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.main.domain
}

