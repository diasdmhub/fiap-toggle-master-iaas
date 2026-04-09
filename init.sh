#!/usr/bin/env bash
set -e
# Desabilita o pager globalmente para evitar pausa nos comandos aws
export AWS_PAGER=""

# 1. Criação do S3 bucket com idempotencia - ignora se já existir

# 1.1 Cria S3 bucket
aws s3api create-bucket \
  --bucket fiap-toggle-terraform-state \
  || true

# 1.2 Habilita o versionamento do bucket
aws s3api put-bucket-versioning \
  --bucket fiap-toggle-terraform-state \
  --versioning-configuration Status=Enabled \
  || true

# 1.3 Habilita a criptografia do bucket
aws s3api put-bucket-encryption \
  --bucket fiap-toggle-terraform-state \
  --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}' \
  || true

# 1.4 Cria a tablea DynamoDB para o arquivo de lock
aws dynamodb create-table \
  --table-name fiap-toggle-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  || true


# 2 Inicialização do Terraform
terraform init -reconfigure