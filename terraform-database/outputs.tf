output "rds_endpoint" {
  description = "Endpoint do RDS PostgreSQL"
  value       = aws_db_instance.postgres.address
}
output "rds_port" {
  description = "Porta do RDS PostgreSQL"
  value       = aws_db_instance.postgres.port
}
output "db_secret_arn" {
  description = "ARN do secret no Secrets Manager"
  value       = aws_secretsmanager_secret.db_secret.arn
}
output "db_secret_name" {
  description = "Nome do secret no Secrets Manager"
  value       = aws_secretsmanager_secret.db_secret.name
}
output "rds_sg_id" {
  description = "Security Group ID do RDS"
  value       = aws_security_group.rds.id
}
output "rds_identifier" {
  description = "Identificador da instância RDS"
  value       = aws_db_instance.postgres.identifier
}
output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.postgres.db_name
}
