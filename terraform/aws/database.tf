locals {
  db_admin_username = "microservicesowner"
}

resource "aws_db_subnet_group" "postgresql" {
  name       = local.naming.rds_subnet_group
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = local.naming.rds_subnet_group
  }
}

resource "aws_security_group" "postgresql" {
  name        = local.naming.postgresql_sg
  description = "Managed PostgreSQL access from EKS nodes"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL from EKS cluster security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]
  }

  egress {
    description = "Allow outbound responses"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.naming.postgresql_sg
  }
}

resource "aws_db_instance" "postgresql" {
  identifier = local.naming.rds_identifier

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = local.db_admin_username
  password = random_password.postgresql_owner.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.postgresql.name
  vpc_security_group_ids = [aws_security_group.postgresql.id]
  publicly_accessible    = false

  backup_retention_period = var.environment == "prod" ? 7 : 1
  deletion_protection     = var.environment == "prod"
  skip_final_snapshot     = var.environment != "prod"
  final_snapshot_identifier = (
    var.environment == "prod"
    ? local.naming.postgresql_final_snap
    : null
  )

  auto_minor_version_upgrade = true
  apply_immediately          = var.environment != "prod"

  tags = {
    Name = local.naming.rds_identifier
  }
}
