# terraform/cognito.tf

resource "aws_cognito_user_pool" "argocd_pool" {
  name = "argocd-users"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "argocd_client" {
  name         = "argocd-client"
  user_pool_id = aws_cognito_user_pool.argocd.id

  allowed_oauth_flows          = ["code"]
  allowed_oauth_scopes         = ["email", "openid", "profile"]
  callback_urls                = ["https://argocd.bunnycloud.xyz/auth/callback"]
  supported_identity_providers = ["COGNITO"]

  generate_secret = true
}

resource "aws_cognito_user_pool_domain" "argocd_domain" {
  domain       = "argocd-auth-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.argocd.id
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create user groups
resource "aws_cognito_user_group" "admin" {
  name         = "Admins"
  user_pool_id = aws_cognito_user_pool.argocd.id
  description  = "Administrator group for ArgoCD"
  precedence   = 1
}

resource "aws_cognito_user_group" "developer" {
  name         = "Developers"
  user_pool_id = aws_cognito_user_pool.argocd.id
  description  = "Developer group for ArgoCD"
  precedence   = 2
}

# Create users
resource "aws_cognito_user" "admin_user" {
  user_pool_id = aws_cognito_user_pool.argocd.id
  username     = "admin1"

  attributes = {
    email          = "admin@example.com"
    email_verified = true
  }

  temporary_password = "Temp123!"
}

resource "aws_cognito_user" "dev_user" {
  user_pool_id = aws_cognito_user_pool.argocd.id
  username     = "dev1"

  attributes = {
    email          = "dev@example.com"
    email_verified = true
  }

  temporary_password = "Temp123!"
}

# Assign users to groups
resource "aws_cognito_user_in_group" "admin_in_admin_group" {
  user_pool_id = aws_cognito_user_pool.argocd.id
  username     = aws_cognito_user.admin_user.username
  group_name   = aws_cognito_user_group.admin.name
}

resource "aws_cognito_user_in_group" "dev_in_dev_group" {
  user_pool_id = aws_cognito_user_pool.argocd.id
  username     = aws_cognito_user.dev_user.username
  group_name   = aws_cognito_user_group.developer.name
}
