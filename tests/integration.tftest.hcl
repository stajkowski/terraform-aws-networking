mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["1a", "1b", "1c", "1d"]
    }
  }
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

variables {
  project_name           = "projecta"
  environment            = "test"
  parent_pool_cidr_block = "10.0.0.0/8"
  network_config = {
    vpcs = {
      "egress" = {
        public_subnets       = 2
        private_subnets      = 2
        vpc_cidr_subnet_mask = 16
        subnet_mask          = 24
        public_subnet_nacl_rules = [
          {
            rule_number = 10
            egress      = false
            action      = "allow"
            protocol    = 6
            cidr_block  = "0.0.0.0/0"
            from_port   = 443
            to_port     = 443
          },
          {
            rule_number = 20
            egress      = false
            action      = "allow"
            protocol    = 6
            cidr_block  = "0.0.0.0/0"
            from_port   = 80
            to_port     = 80
          },
          {
            rule_number = 10
            egress      = true
            action      = "allow"
            protocol    = -1
            cidr_block  = "0.0.0.0/0"
            from_port   = 0
            to_port     = 0
          }
        ]
        private_subnet_nacl_rules = [
          {
            rule_number = 10
            egress      = false
            action      = "allow"
            protocol    = -1
            cidr_block  = "infra1"
            from_port   = 0
            to_port     = 0
          },
          {
            rule_number = 20
            egress      = false
            action      = "allow"
            protocol    = 6
            cidr_block  = "ipam_account_pool"
            from_port   = 22
            to_port     = 22
          },
          {
            rule_number = 10
            egress      = true
            action      = "allow"
            protocol    = -1
            cidr_block  = "0.0.0.0/0"
            from_port   = 0
            to_port     = 0
          }
        ]
        gw_services = {
          igw_is_enabled       = true
          nat_gw_is_enabled    = true
          nat_gw_type          = "public"
          nat_gw_ha            = true
          vpc_gateway_services = ["s3"]
          vpc_interface_services = [
            "ec2", "sts"
          ]
          vpc_interface_services_scope = "private"
        }
        tgw_config = {
          route_destinations = ["infra1"]
        }
      }
      "infra1" = {
        public_subnets       = 0
        private_subnets      = 2
        vpc_cidr_subnet_mask = 16
        subnet_mask          = 24
        public_subnet_nacl_rules = [
          {
            rule_number = 10
            egress      = false
            action      = "allow"
            protocol    = 6
            cidr_block  = "0.0.0.0/0"
            from_port   = 443
            to_port     = 443
          },
          {
            rule_number = 20
            egress      = false
            action      = "allow"
            protocol    = 6
            cidr_block  = "0.0.0.0/0"
            from_port   = 80
            to_port     = 80
          },
          {
            rule_number = 30
            egress      = false
            action      = "allow"
            protocol    = 6
            cidr_block  = "0.0.0.0/0"
            from_port   = 1024
            to_port     = 65535
          },
          {
            rule_number = 10
            egress      = true
            action      = "allow"
            protocol    = -1
            cidr_block  = "0.0.0.0/0"
            from_port   = 0
            to_port     = 0
          }
        ]
        private_subnet_nacl_rules = [
          {
            rule_number = 10
            egress      = false
            action      = "allow"
            protocol    = 6
            cidr_block  = "0.0.0.0/0"
            from_port   = 1024
            to_port     = 65535
          },
          {
            rule_number = 20
            egress      = false
            action      = "allow"
            protocol    = 6
            cidr_block  = "egress"
            from_port   = 22
            to_port     = 22
          },
          {
            rule_number = 10
            egress      = true
            action      = "allow"
            protocol    = -1
            cidr_block  = "0.0.0.0/0"
            from_port   = 0
            to_port     = 0
          }
        ]
        gw_services = {
          igw_is_enabled       = false
          nat_gw_is_enabled    = false
          nat_gw_type          = "private"
          nat_gw_ha            = false
          vpc_gateway_services = []
          vpc_interface_services = [
            "ec2", "sts"
          ]
          vpc_interface_services_scope = "private"
        }
        tgw_config = {
          route_destinations = ["0.0.0.0/0"]
        }
      }
    }
    transit_gw = {
      tgw_is_enabled = true
      tgw_vpc_attach = ["infra1", "egress"]
    }
  }
}

run "positive_integration_test_with_known_good_configuration" {
  command = plan

  assert {
    condition     = length(module.aws-vpc) == 2
    error_message = "Expected 2 VPCs Created"
  }

}