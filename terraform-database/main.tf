locals {
  name = var.project_name
  tags = {
    Project = var.project_name
    Stack   = "db-postgres-aws"
    Owner   = "team"
  }
}

# --------- SG do RDS (permite acesso apenas de SGs autorizados) ---------
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Acesso ao PostgreSQL apenas de SGs permitidos"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "ingress_from_allowed_sg" {
  for_each = toset(var.allowed_sg_ids)
  type              = "ingress"
  security_group_id = aws_security_group.rds.id
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  source_security_group_id = each.value
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.rds.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# --------- Subnet group ---------
resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-rds-subnetgrp"
  subnet_ids = var.private_subnet_ids
  tags       = local.tags
}

# --------- Secrets: usuário/senha ---------
resource "random_password" "db" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "${local.name}/rds/postgres"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.db.result
    engine   = "postgres"
    host     = null
    port     = 5432
    dbname   = var.db_name
  })
}

# --------- Parameter group (opcional) ---------
resource "aws_db_parameter_group" "pg" {
  name        = "${local.name}-pg16"
  family      = "postgres16"
  description = "Parâmetros Postgres 16"
  tags        = local.tags

  # example:
  parameter {
    name  = "log_min_duration_statement"
    value = "2000"
  }
}

# --------- RDS PostgreSQL ---------
resource "aws_db_instance" "postgres" {
  identifier                 = "${local.name}-postgres"
  engine                     = "postgres"
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class

  db_name                    = var.db_name
  username                   = "app_user"
  password                   = random_password.db.result

  allocated_storage          = 20
  max_allocated_storage      = 20
  storage_encrypted          = var.storage_encrypted
  storage_type               = "gp2"
  backup_retention_period    = var.backup_retention_period
  deletion_protection        = var.deletion_protection
  multi_az                   = var.multi_az
  publicly_accessible        = false

  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  parameter_group_name       = aws_db_parameter_group.pg.name

  maintenance_window         = "Sun:02:00-Sun:03:00"
  backup_window              = "03:00-04:00"

  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn

  # Prevenção contra destruição acidental
  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags

  depends_on = [aws_secretsmanager_secret_version.db_secret_value]
}

# --------- IAM Role para Enhanced Monitoring ---------
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Atualiza o secret com o host após criação
resource "aws_secretsmanager_secret_version" "db_secret_value_with_host" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.db.result
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = 5432
    dbname   = var.db_name
  })
  depends_on = [aws_db_instance.postgres]
}
