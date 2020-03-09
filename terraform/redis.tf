resource aws_security_group redis {
  name   = "ci-poc-redis"
  vpc_id = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.service.id]
  }
}

resource aws_elasticache_subnet_group redis {
  name       = "ci-poc"
  subnet_ids = data.aws_subnet_ids.private.ids
}

resource aws_elasticache_cluster redis {
  cluster_id         = "ci-poc"
  engine             = "redis"
  node_type          = "cache.t3.micro"
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]
  num_cache_nodes    = 1
}
