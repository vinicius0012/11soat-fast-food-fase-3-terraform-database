variable "project_name" {
  description = "Nome base do projeto (prefixo de recursos)."
  type        = string
}
variable "aws_region" {
  description = "Região AWS."
  type        = string
  default     = "sa-east-1"
}
variable "vpc_id" {
  description = "VPC onde o RDS ficará."
  type        = string
}
variable "private_subnet_ids" {
  description = "Subnets privadas para o RDS."
  type        = list(string)
}
variable "allowed_sg_ids" {
  description = "Security Groups que podem acessar o RDS (ex.: EKS nodes, Lambda)."
  type        = list(string)
  default     = []
}
variable "db_engine_version" {
  description = "Versão do PostgreSQL."
  type        = string
  default     = "16.3"
}
variable "db_instance_class" {
  description = "Classe da instância."
  type        = string
  default     = "db.t4g.medium"
}
variable "db_name" {
  description = "Nome do database."
  type        = string
  default     = "appdb"
}
variable "deletion_protection" {
  description = "Proteção contra deleção do banco."
  type        = bool
  default     = true
}
variable "backup_retention_period" {
  description = "Período de retenção de backup em dias."
  type        = number
  default     = 7
}
variable "storage_encrypted" {
  description = "Habilita encriptação do storage."
  type        = bool
  default     = true
}
variable "multi_az" {
  description = "Habilita Multi-AZ para alta disponibilidade."
  type        = bool
  default     = true
}
variable "performance_insights_enabled" {
  description = "Habilita Performance Insights."
  type        = bool
  default     = true
}
