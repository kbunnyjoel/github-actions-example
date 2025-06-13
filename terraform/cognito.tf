# terraform/cognito.tf

resource "aws_cognito_user_pool" "argocd_pool" {
  name = "argocd-users"

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 1
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  auto_verified_attributes = ["email"]

  # Enable MFA for additional security
  mfa_configuration = "OPTIONAL"

  # Advanced security features
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }
}

resource "aws_cognito_user_pool_client" "argocd_client" {
  name         = "argocd-client"
  user_pool_id = aws_cognito_user_pool.argocd_pool.id

  allowed_oauth_flows          = ["code"]
  allowed_oauth_scopes         = ["email", "openid", "profile"]
  callback_urls                = ["https://argocd.bunnycloud.xyz/auth/callback"]
  supported_identity_providers = ["COGNITO"]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Set token validity periods
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  generate_secret = true

  # Explicitly define auth flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_cognito_user_pool_domain" "argocd_domain" {
  domain       = "argocd-auth-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.argocd_pool.id

  # Add custom domain with SSL certificate (uncomment and configure when ready)
  # certificate_arn = aws_acm_certificate.auth_cert.arn
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create user groups
resource "aws_cognito_user_group" "admin" {
  name         = "Admins"
  user_pool_id = aws_cognito_user_pool.argocd_pool.id
  description  = "Administrator group for ArgoCD"
  precedence   = 1
}

resource "aws_cognito_user_group" "developer" {
  name         = "Developers"
  user_pool_id = aws_cognito_user_pool.argocd_pool.id
  description  = "Developer group for ArgoCD"
  precedence   = 2
}

# Create users
resource "aws_cognito_user" "admin_user" {
  user_pool_id = aws_cognito_user_pool.argocd_pool.id
  username     = "admin1"

  attributes = {
    email          = "admin@example.com"
    email_verified = true
  }

  # Use SSM Parameter Store for temporary passwords
  temporary_password = aws_ssm_parameter.admin_temp_password.value
}

resource "aws_cognito_user" "dev_user" {
  user_pool_id = aws_cognito_user_pool.argocd_pool.id
  username     = "dev1"

  attributes = {
    email          = "dev@example.com"
    email_verified = true
  }

  # Use SSM Parameter Store for temporary passwords
  temporary_password = aws_ssm_parameter.dev_temp_password.value
}

# Store temporary passwords securely in SSM Parameter Store
resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}|;:,.<>?"
}

resource "random_password" "dev_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}|;:,.<>?"
}

resource "aws_ssm_parameter" "admin_temp_password" {
  name        = "/argocd/cognito/admin_temp_password"
  description = "Temporary password for ArgoCD admin user"
  type        = "SecureString"
  value       = random_password.admin_password.result
}

resource "aws_ssm_parameter" "dev_temp_password" {
  name        = "/argocd/cognito/dev_temp_password"
  description = "Temporary password for ArgoCD developer user"
  type        = "SecureString"
  value       = random_password.dev_password.result
}

# Assign users to groups
resource "aws_cognito_user_in_group" "admin_in_admin_group" {
  user_pool_id = aws_cognito_user_pool.argocd_pool.id
  username     = aws_cognito_user.admin_user.username
  group_name   = aws_cognito_user_group.admin.name
}

resource "aws_cognito_user_in_group" "dev_in_dev_group" {
  user_pool_id = aws_cognito_user_pool.argocd_pool.id
  username     = aws_cognito_user.dev_user.username
  group_name   = aws_cognito_user_group.developer.name
}
