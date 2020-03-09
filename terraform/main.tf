terraform {
  backend s3 {
    region = "us-east-1"
    key    = "ci-poc.tfstate"
  }
}

provider aws {
  region = "us-east-1"
}

provider aws {
  alias  = "route53"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.route53_account}:role/CrossAccountRoute53"
  }
}

data aws_region current {}
data aws_caller_identity current {}

data aws_route53_zone zone {
  provider     = aws.route53
  name         = "staging.resolver.com."
  private_zone = false
}

data aws_vpc vpc {
  tags = {
    Application = "core"
  }
}

data aws_subnet_ids private {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Application = "core"
    Tier        = "private"
  }
}

data aws_acm_certificate cert {
  domain      = "*.staging.resolver.com"
  most_recent = true
}
