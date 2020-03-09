resource aws_security_group service {
  name   = "ci-poc-service"
  vpc_id = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }
}

resource aws_ecs_cluster cluster {
  name               = "ci-poc"
  capacity_providers = ["FARGATE"]
}

resource aws_iam_role ecs_task {
  name               = "feature-server-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks.json
}

resource aws_iam_role_policy_attachment ecs_task {
  role       = aws_iam_role.ecs_task.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data aws_iam_policy_document ecs_tasks {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource aws_ecs_task_definition service {
  family = "ci-poc"
  cpu    = 256
  memory = 512

  network_mode = "awsvpc"

  execution_role_arn       = aws_iam_role.ecs_task.arn
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name      = "service"
      essential = true
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ci-poc:${var.service_version}"
      portMappings = [
        { containerPort = 8080 }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      },
      environment = [
        { name = "REDIS_ADDR", value = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}" },
      ],
    }
  ])
}

resource aws_cloudwatch_log_group service {
  name              = "/ecs/ci-poc"
  retention_in_days = 30
}

resource aws_ecs_service service {
  name            = "service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  launch_type     = "FARGATE"
  desired_count   = 1


  network_configuration {
    subnets         = data.aws_subnet_ids.private.ids
    security_groups = [aws_security_group.service.id]
  }

  load_balancer {
    container_name   = "service"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.service.arn
  }

  depends_on = [
    aws_lb_listener.https,
  ]
}

resource aws_security_group lb {
  name   = "ci-poc-lb"
  vpc_id = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource aws_lb service {
  name            = "ci-poc"
  internal        = true
  subnets         = data.aws_subnet_ids.private.ids
  security_groups = [aws_security_group.lb.id]
}

resource aws_lb_target_group service {
  name                 = "ci-poc"
  deregistration_delay = 15
  target_type          = "ip"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.vpc.id
}

resource aws_lb_listener http {
  load_balancer_arn = aws_lb.service.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource aws_lb_listener https {
  load_balancer_arn = aws_lb.service.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }
}


resource aws_route53_record service {
  provider = aws.route53
  type     = "A"
  name     = var.domain_prefix
  zone_id  = data.aws_route53_zone.zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.service.dns_name
    zone_id                = aws_lb.service.zone_id
  }
}
