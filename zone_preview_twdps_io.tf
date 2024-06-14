# *.preview.twdps.io

# define a provider in the account where this subdomain will be managed
provider "aws" {
  alias  = "subdomain_preview_twdps_io"
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::${var.nonprod_account_id}:role/${var.assume_role}"
    session_name = "psk-aws-platform-hosted-zones"
  }
}

# create a route53 hosted zone for the subdomain in the account defined by the provider above
module "subdomain_preview_twdps_io" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "3.1.0"
  create  = true

  providers = {
    aws = aws.subdomain_preview_twdps_io
  }

  zones = {
    "preview.${local.domain_twdps_io}" = {
      tags = {
        cluster = "sbx-i01-aws-us-east-1"
      }
    }
  }

  tags = {
    pipeline = "psk-aws-platform-hosted-zones"
  }
}

# Create a zone delegation in the top level domain for this subdomain
module "subdomain_zone_delegation_preview_twdps_io" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "3.1.0"
  create  = true

  providers = {
    aws = aws.domain_twdps_io
  }

  private_zone = false
  zone_name = local.domain_twdps_io
  records = [
    {
      name            = "preview"
      type            = "NS"
      ttl             = 172800
      zone_id         = data.aws_route53_zone.zone_id_twdps_io.id
      allow_overwrite = true
      records         = module.subdomain_preview_twdps_io.route53_zone_name_servers["preview.${local.domain_twdps_io}"]
    }
  ]

  depends_on = [module.subdomain_preview_twdps_io]
}
