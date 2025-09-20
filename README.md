# 🗄️ Fast Food Database Infrastructure - Terraform

[![Terraform](https://img.shields.io/badge/Terraform-v1.6+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-RDS_PostgreSQL-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/rds/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16.3-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

Infraestrutura como código (IaC) para provisionamento de banco de dados PostgreSQL na AWS usando Amazon RDS, desenvolvida para o **Tech Challenge FIAP - 11SOAT Fase 3**.

## 📋 Visão Geral

Este módulo Terraform provisiona uma infraestrutura completa de banco de dados PostgreSQL na AWS, seguindo as melhores práticas de segurança, alta disponibilidade e monitoramento para aplicações em produção.

### 🏗️ Recursos Provisionados

- **🗄️ Amazon RDS PostgreSQL 16.3**
  - Multi-AZ para alta disponibilidade
  - Storage GP3 com auto-scaling (50GB-200GB)
  - Backup automatizado com retenção configurável
  - Encryption em repouso habilitada

- **🔐 Segurança**
  - Security Groups restritivos
  - Subnets privadas isoladas
  - AWS Secrets Manager para credenciais
  - Senhas geradas automaticamente

- **📊 Monitoramento & Performance**
  - CloudWatch Logs habilitados
  - Performance Insights ativado
  - Enhanced Monitoring configurado
  - Parameter Group customizado

- **🛡️ Proteções**
  - Deletion Protection habilitada
  - Lifecycle prevent_destroy
  - Backup retention configurável

## 🚀 Pré-requisitos

- [Terraform](https://www.terraform.io/downloads.html) >= 1.6.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- Credenciais AWS com permissões adequadas
- VPC existente com subnets privadas
- Security Groups de origem (EKS nodes, Lambda, etc.)

## 📦 Como Usar

### 1. Clone o repositório
```bash
git clone <repository-url>
cd 11soat-fast-food-fase-3-terraform-database/terraform-database
```

### 2. Configure as variáveis
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite o arquivo `terraform.tfvars` com seus valores:

```hcl
# Configurações obrigatórias
project_name         = "fastfood"
vpc_id              = "vpc-xxxxxxxxx"
private_subnet_ids  = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
allowed_sg_ids      = ["sg-eks-nodes", "sg-lambda"]

# Configurações opcionais
aws_region                    = "sa-east-1"
db_instance_class            = "db.t4g.medium"
db_name                      = "fastfooddb"
```

### 3. Deploy da infraestrutura
```bash
# Inicializar o Terraform
terraform init

# Verificar o plano de execução
terraform plan

# Aplicar as mudanças
terraform apply
```

### 4. Obter as informações de conexão
```bash
# Endpoint do banco
terraform output rds_endpoint

# ARN do secret com credenciais
terraform output db_secret_arn
```

## 📝 Variáveis de Entrada

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| `project_name` | Nome base do projeto | `string` | - | ✅ |
| `vpc_id` | ID da VPC onde o RDS será criado | `string` | - | ✅ |
| `private_subnet_ids` | IDs das subnets privadas | `list(string)` | - | ✅ |
| `allowed_sg_ids` | Security Groups autorizados | `list(string)` | `[]` | ❌ |
| `aws_region` | Região AWS | `string` | `"sa-east-1"` | ❌ |
| `db_engine_version` | Versão do PostgreSQL | `string` | `"16.3"` | ❌ |
| `db_instance_class` | Classe da instância | `string` | `"db.t4g.medium"` | ❌ |
| `db_name` | Nome do banco de dados | `string` | `"appdb"` | ❌ |
| `deletion_protection` | Proteção contra deleção | `bool` | `true` | ❌ |
| `backup_retention_period` | Período de retenção de backup | `number` | `7` | ❌ |
| `multi_az` | Habilita Multi-AZ | `bool` | `true` | ❌ |
| `performance_insights_enabled` | Habilita Performance Insights | `bool` | `true` | ❌ |

## 📤 Outputs

| Nome | Descrição |
|------|-----------|
| `rds_endpoint` | Endpoint do RDS PostgreSQL |
| `rds_port` | Porta do RDS PostgreSQL |
| `db_secret_arn` | ARN do secret no Secrets Manager |
| `db_secret_name` | Nome do secret no Secrets Manager |
| `rds_sg_id` | Security Group ID do RDS |
| `rds_identifier` | Identificador da instância RDS |
| `db_name` | Nome do banco de dados |

## 🔧 Configuração da Aplicação

Para conectar sua aplicação ao banco, recupere as credenciais do AWS Secrets Manager:

### Node.js/NestJS
```typescript
import { SecretsManager } from '@aws-sdk/client-secrets-manager';

const secretsManager = new SecretsManager({ region: 'sa-east-1' });
const secret = await secretsManager.getSecretValue({ 
  SecretId: 'fastfood/rds/postgres' 
});

const dbConfig = JSON.parse(secret.SecretString);
```

### Variáveis de Ambiente
```bash
export DB_HOST=$(terraform output -raw rds_endpoint)
export DB_SECRET_ARN=$(terraform output -raw db_secret_arn)
```

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                        VPC                               │
│  ┌─────────────────┐              ┌─────────────────┐   │
│  │  Private Subnet │              │  Private Subnet │   │
│  │       AZ-a      │              │       AZ-b      │   │
│  │                 │              │                 │   │
│  │  ┌───────────┐  │              │  ┌───────────┐  │   │
│  │  │    RDS    │  │◄────────────►│  │    RDS    │  │   │
│  │  │ Primary   │  │              │  │ Standby   │  │   │
│  │  └───────────┘  │              │  └───────────┘  │   │
│  └─────────────────┘              └─────────────────┘   │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Secrets Manager │
                    │   Credentials   │
                    └─────────────────┘
```

## 🔒 Segurança

- **Encryption**: Storage e backups encriptados com KMS
- **Network**: Banco em subnets privadas, sem acesso público
- **Access Control**: Security Groups restritivos
- **Credentials**: Senhas geradas automaticamente e armazenadas no Secrets Manager
- **Monitoring**: CloudWatch Logs para auditoria

## 📊 Monitoramento

- **CloudWatch Logs**: Logs do PostgreSQL exportados automaticamente
- **Performance Insights**: Análise de performance em tempo real
- **Enhanced Monitoring**: Métricas detalhadas do SO (60s)
- **Backup Monitoring**: Alertas de backup via CloudWatch

## 🧹 Limpeza

Para destruir a infraestrutura:

```bash
# Remover proteção contra deleção (se necessário)
terraform apply -var="deletion_protection=false"

# Destruir recursos
terraform destroy
```
