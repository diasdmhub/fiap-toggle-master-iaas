# Subnet Group com as subnets privadas
resource "aws_elasticache_subnet_group" "valkey" {
  name       = "${var.name_prefix}-valkey-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.name_prefix}-valkey-subnet-group"
  }
}

# Security Group para o Valkey a partir da VPC
resource "aws_security_group" "valkey" {
  name        = "${var.name_prefix}-valkey-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security Group para o Valkey a partir da VPC"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
    description = "Acesso ao Valkey a partir da VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permite todo o tráfego de saída"
  }

  tags = {
    Name = "${var.name_prefix}-valkey-sg"
  }
}

# Instância Valkey Serveless
resource "aws_elasticache_serverless_cache" "valkey" {
  name = "${var.name_prefix}-valkey"

  engine         = "valkey"
  engine_version = "8.2"

  # Configuração mínima de scaling automático
  cache_usage_limits {
    data_storage {
      maximum = 2
    }
    ecpu_per_second {
      maximum = 1000
    }
  }

  subnet_group_name  = aws_elasticache_subnet_group.valkey.name
  security_group_ids = [aws_security_group.valkey.id]

  # Sem backups automáticos
  snapshot_retention_limit = 0

  tags = {
    Name = "${var.name_prefix}-valkey"
  }

  depends_on = [
    aws_elasticache_subnet_group.valkey,
    aws_security_group.valkey
  ]
}