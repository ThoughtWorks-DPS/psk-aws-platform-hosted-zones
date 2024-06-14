# *.prod.twdps.digital

# define a provider in the account where this subdomain will be managed
provider "aws" {
  alias  = "subdomain_prod_twdps_digital"
  region = "us-east-2"
  assume_role {
    role_arn     = "arn:aws:iam::${var.prod_account_id}:role/${var.assume_role}"
    session_name = "psk-aws-platform-hosted-zones"
  }
}

# create a route53 hosted zone for the subdomain in the account defined by the provider above
module "subdomain_prod_twdps_digital" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "3.1.0"
  create  = true

  providers = {
    aws = aws.subdomain_prod_twdps_digital
  }

  zones = {
    "prod.${local.domain_twdps_digital}" = {
      tags = {
        cluster = "prod-i01-aws-us-east-2"
      }
    }
  }

  tags = {
    pipeline = "psk-aws-platform-hosted-zones"
  }
}

# Create a zone delegation in the top level domain for this subdomain
module "subdomain_zone_delegation_prod_twdps_digital" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "3.1.0"
  create  = true

  providers = {
    aws = aws.domain_twdps_digital
  }

  private_zone = false
  zone_name = local.domain_twdps_digital
  records = [
    {
      name            = "prod"
      type            = "NS"
      ttl             = 172800
      zone_id         = data.aws_route53_zone.zone_id_twdps_digital.id
      allow_overwrite = true
      records         = module.subdomain_prod_twdps_digital.route53_zone_name_servers["prod.${local.domain_twdps_digital}"]
    }
  ]

  depends_on = [module.subdomain_prod_twdps_digital]
}
