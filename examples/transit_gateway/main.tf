locals {
  project_name           = "projecta"
  environment            = "test"
  parent_pool_cidr_block = "10.0.0.0/8"
  ipam_scope_id          = null
  network_config = {
    "test" = {
      vpcs = {
        "egress" = {
          public_subnets             = 2
          private_subnets            = 2
          vpc_cidr_subnet_mask       = 16
          subnet_mask                = 24
          additional_private_subnets = {}
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
          additional_private_subnets = {
            "db" = {
              subnet_count = 2
              nacl_rules = [
                {
                  rule_number = 10
                  egress      = false
                  action      = "allow"
                  protocol    = 6
                  cidr_block  = "infra1"
                  from_port   = 3306
                  to_port     = 3306
                },
                {
                  rule_number = 20
                  egress      = false
                  action      = "allow"
                  protocol    = 6
                  cidr_block  = "ipam_account_pool"
                  from_port   = 1024
                  to_port     = 65535
                },
                {
                  rule_number = 10
                  egress      = true
                  action      = "allow"
                  protocol    = -1
                  cidr_block  = "ipam_account_pool"
                  from_port   = 0
                  to_port     = 0
                }
              ]
            }
          }
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
        tgw_routes = [
          {
            "destination"    = "0.0.0.0/0"
            "vpc_attachment" = "egress"
          }
        ]
      }
      internet_monitor = {
        is_enabled                    = true
        monitor_vpcs                  = ["egress"]
        traffic_percentage_to_monitor = 50
        max_city_networks_to_monitor  = 100
        availability_threshold        = 96
        performance_threshold         = 96
        status                        = "ACTIVE"
        alarm_config = {
          sns_topics = {
            "egress-alarms" = {}
          }
          sns_subscriptions = [
            {
              topic    = "egress-alarms"
              protocol = "email"
              endpoint = "infra-alerts@example.com"
            }
          ]
          alarms = {
            "egress-availability-score" = {
              description         = "AWS Iternet Monitor Egress availability score less than 96 for 5m."
              comparison          = "LessThanThreshold"
              metric_name         = "AvailabilityScore"
              namespace           = "AWS/InternetMonitor"
              statistic           = "Average"
              period              = 300
              threshold           = 96
              evaluation_periods  = 2
              datapoints_to_alarm = 2
              actions_enabled     = true
              treat_missing_data  = "missing"
              alarm_actions = [
                "egress-alarms"
              ]
            }
            "egress-performance-score" = {
              description         = "AWS Iternet Monitor Egress performance score less than 96 for 5m."
              comparison          = "LessThanThreshold"
              metric_name         = "PerformanceScore"
              namespace           = "AWS/InternetMonitor"
              statistic           = "Average"
              period              = 300
              threshold           = 96
              evaluation_periods  = 2
              datapoints_to_alarm = 2
              actions_enabled     = true
              treat_missing_data  = "missing"
              alarm_actions = [
                "egress-alarms"
              ]
            }
          }
        }
      }
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "aws-networking" {
  source                 = "../../"
  project_name           = local.project_name
  environment            = local.environment
  parent_pool_cidr_block = local.parent_pool_cidr_block
  ipam_scope_id          = local.ipam_scope_id
  network_config         = local.network_config[local.environment]
}