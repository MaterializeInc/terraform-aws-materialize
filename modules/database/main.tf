module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.db_identifier

  engine               = "postgres"
  engine_version       = var.postgres_version
  family               = "postgres${var.postgres_version}"
  major_engine_version = var.postgres_version
  instance_class       = var.instance_class

  password = var.database_password

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.database_username
  port     = 5432

  multi_az               = var.multi_az
  subnet_ids             = var.database_subnet_ids
  vpc_security_group_ids = [aws_security_group.database.id]
  create_db_subnet_group = true
  db_subnet_group_name   = "${var.db_identifier}-subnet-group"

  maintenance_window      = var.maintenance_window
  backup_window           = var.backup_window
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = true

  tags = var.tags

  depends_on = [aws_security_group.database]
}

resource "aws_security_group" "database" {
  name_prefix = "materialize-db-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.db_identifier}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
