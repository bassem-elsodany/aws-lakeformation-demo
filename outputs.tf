################################################################################
# MYSQL
################################################################################

output "db_mysql_instance_address" {
  description = "The address of the RDS instance"
  value       = module.mysql-db.db_instance_address
}

output "db_mysql_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.mysql-db.db_instance_arn
}

output "db_mysql_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.mysql-db.db_instance_endpoint
}

output "db_mysql_instance_id" {
  description = "The RDS instance ID"
  value       = module.mysql-db.db_instance_id
}


output "db_mysql_instance_status" {
  description = "The RDS instance status"
  value       = module.mysql-db.db_instance_status
}

output "db_mysql_instance_name" {
  description = "The database name"
  value       = module.mysql-db.db_instance_name
}

output "db_mysql_instance_username" {
  description = "The master username for the database"
  value       = module.mysql-db.db_instance_username
  sensitive   = true
}

output "db_mysql_instance_password" {
  description = "The database password (this password may be old, because Terraform doesn't track it after initial creation)"
  value       = module.mysql-db.db_instance_password
  sensitive   = true
}

output "db_mysql_instance_port" {
  description = "The database port"
  value       = module.mysql-db.db_instance_port
}



################################################################################
# POSTGRESQL
################################################################################

output "db_postgres_instance_address" {
  description = "The address of the RDS instance"
  value       = module.postgres-db.db_instance_address
}

output "db_postgres_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.postgres-db.db_instance_arn
}

output "db_postgres_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.postgres-db.db_instance_endpoint
}


output "db_postgres_instance_id" {
  description = "The RDS instance ID"
  value       = module.postgres-db.db_instance_id
}

output "db_postgres_instance_status" {
  description = "The RDS instance status"
  value       = module.postgres-db.db_instance_status
}

output "db_postgres_instance_name" {
  description = "The database name"
  value       = module.postgres-db.db_instance_name
}

output "db_postgres_instance_username" {
  description = "The master username for the database"
  value       = module.postgres-db.db_instance_username
  sensitive   = true
}

output "db_postgres_instance_password" {
  description = "The database password (this password may be old, because Terraform doesn't track it after initial creation)"
  value       = module.postgres-db.db_instance_password
  sensitive   = true
}

output "db_postgres_instance_port" {
  description = "The database port"
  value       = module.postgres-db.db_instance_port
}



################################################################################
# USERS
################################################################################


output "iam_user_name" {
  description = "The user's name"
  value       = module.iam_user_admin_lakeformation.iam_user_name
}

output "iam_user_arn" {
  description = "The ARN assigned by AWS for this user"
  value       = module.iam_user_admin_lakeformation.iam_user_arn
}

output "iam_user_unique_id" {
  description = "The unique ID assigned by AWS"
  value       = module.iam_user_admin_lakeformation.iam_user_unique_id
}

output "iam_user_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value       = module.iam_user_admin_lakeformation.iam_user_login_profile_encrypted_password
}

output "iam_access_key_id" {
  description = "The access key ID"
  value       = module.iam_user_admin_lakeformation.iam_access_key_id
}

output "iam_access_key_secret" {
  description = "The access key secret"
  value       = module.iam_user_admin_lakeformation.iam_access_key_secret
  sensitive   = true
}