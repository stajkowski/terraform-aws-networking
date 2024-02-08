# aws-networking ![GitHub Release](https://img.shields.io/github/v/release/stajkowski/aws-networking)
Terraform Module to simplify the creation of complex AWS VPC Networking configurations.  With a layer of abstraction, you can create multiple vpcs and connect them with Transit Gateway through configurations.  Control NACLs, Security Groups and Routing with simple shorthand reference to the VPC, and aws-networking module to ensure the correct values are substituted.  VPC CIDR assignments are derived from the account level IPAM pool and auto assigns VPC CIRDs and Subnet CIDRs.

## Examples
```
variables {
  environment            = "test"
  project_name           = "projecta"
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

module "aws-networking" {
  source      = "../../modules/aws-networking"
  project_name = "projecta"
  environment = var.environment
  parent_pool_cidr_block = var.parent_cidr
  network_config = local.env_network_config[var.environment]
}
```
The following example will create:

1. A parent IPAM pool with CIDR 10.0.0.0/8
2. 2 VPCs, one name "egress" and the other named "infra1" with CIDRs assigned from the parent pool.
3. In the "egress" VPC, 2 public subnets and 2 private with CIDRs assigned from the "egress" VPC pool.
4. In the "infra1" VPC, 2 private subnets with CIDRs assigned from the "infra1" VPC pool.
5. In the "egress" VPC, 1 public route table and 2 private route tables (NAT Gateway HA).
6. In the "infra1" VPC, 1 private route table.
6. NACLs for each public/private subnet and assigned.
7. In the "egress" VPC, an Internet Gateway and 2 NAT Gateways (NAT GW in each private subnet).
8. In the "egress" VPC, a VPCE Gateway is added for "s3" in the public/private route tables.
8. In the "egress" VPC, private link support is added ("ec2 &"sts") to each private subnet since scope is "private".
9. In the "infra1" VPC, private link support is added ("ec2 &"sts") to each private subnet since scope is "private".
10. A single Transit Gateway with VPCs "egress" and "infra1" attached.
11. Route destination "0.0.0.0/0" is added to the private route tables in "infra1" VPC.
12. Route destination "infra1" (auto substituted for infra 1 CIDR) is added to public/private route tables in "egress" VPC.
13. A default security group that can be used per VPC that allows parent IPAM pool CIDR of "10.0.0.0/8"

*NOTE*: Size of each VPC CIDR and subnet mask can be controlled through the configuration "vpc_cidr_subnet_mask" and "subnet_mask"

## Requirements

| Name      | Version   |
|-----------|-----------|
| Terraform | >= 1.0.0  |
| aws       | ~> 5.34.0 |

## Providers

| Name      | Version   |
|-----------|-----------|
| aws       | ~> 5.34.0 |

## Resources

| Name      | Type   |
|-----------|-----------|
| aws_ec2_transit_gateway       | resource |
| aws_ec2_transit_gateway_vpc_attachment       | resource |
| aws_eip       | resource |
| aws_internet_gateway       | resource |
| aws_nat_gateway       | resource |
| aws_network_acl       | resource |
| aws_network_acl_rule       | resource |
| aws_network_acl_association       | resource |
| aws_route       | resource |
| aws_route_table       | resource |
| aws_route_table_association       | resource |
| aws_subnet       | resource |
| aws_vpc_endpoint       | resource |
| aws_vpc_ipam       | resource |
| aws_vpc_ipam_pool       | resource |
| aws_vpc_ipam_pool_cidr       | resource |
| aws_vpc_ipam_pool_cidr_allocation       | resource |
| aws_vpc       | resource |

## Inputs
| Name      | Description   | Type    |
|-----------|-----------|-----------|
| project_name | Generally referred to as the namespace. This can be any value used to identify the parent set of objects created in the environment. | `string`
| environment | Current environment stage to configure.  This value is only utilized in naming resources and applying tags. | `string`
| network_config | Network configuration values utilized to standup VPC resources. | `object()`

#### Network Configuration Inputs
| Name      | Description   | Type    |
|-----------|-----------|-----------|
| vpcs.public_subnets | Number of public subnets to create in the VPC.  This is required to be > 0 if an Internet Gateway is configured for the VPC. | `number`
| vpcs.private_subnets | Number of private subnets to create in the VPC.  This is required to be > 0 if a priate NAT Gateway is configured for the VPC. | `number`
| vpcs.vpc_cidr_subnet_mask | Length of mask for auto assignment of the VPC CIDR. | `number`
| vpcs.subnet_mask | Length of mask for auto assignment of VPC Subnets. | `number`
| vpcs.gw_services.igw_is_enabled | Boolean value to indicate if an Internet Gateway is to be configured for the VPC. | `bool`
| vpcs.gw_services.nat_gw_is_enabled | Boolean value to indicate if a NAT Gateway is to be configured for the VPC. | `bool`
| vpcs.gw_services.nat_gw_type | (`public`, `private`) NAT Gateway type is direct confgiuration of the aws module and can be public or private.  Public NAT Gateway requires creation of an Internet Gateway to allow traffic to exit to the Internet. Private NAT Gateways: https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/private-nat-gateway.html. Public NAT Gateway Architecture: https://docs.aws.amazon.com/network-firewall/latest/developerguide/arch-igw-ngw.html | `string`
| vpcs.gw_services.nat_gw_ha | Boolean to configure NAT Gateway in High Availability.  Essentially this creates a route table per private subnet and associates an EIP and NAT Gateway per route table.  This is the recommended configuration for High Availability. | `bool`
| vpcs.gw_services.vpc_gateway_services | This is a list of VPCE Gateway services to create and associate with public/private subnets.  Please refer to AWS Documentation on which services support VPCE Gateway but as of this release, only "s3" and "dynamodb" are supported. | `list(string)`
| vpcs.gw_services.vpc_interface_services | This is a list of services to create Interface Endpoints (PrivateLink).  The difference between VPCE Gateway and Interface Endpoint (PrivateLink), is that Interface Endpoint allows access to AWS services through an IP Address assigned from within your subnets, whereas, VPCE Gateway endpoints inject routes into your associated routing tables. Please refer to AWS documentation for supported services (https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html) and please use the service name in the endpoint, i.e. for "com.amazonaws.us-east-1.s3" you would set this configuration to ["s3"] | `list(string)`
| vpcs.gw_services.vpc_interface_services_scope | (`private`, `both`) This will control in aws-networking module which subnets to attach to the Interface Endpoint.  `private` will attach only private subnets, whereas `both` will assign both public and private subnets to the Interface Endpoint.
| vpcs.public_subnet_nacl_rules | This will iterate over the configured NACL rules and assign them to the public route table. This is direct configuration of NACL Rules in AWS with support for dynamic names of VPCs in the cidr_block within aws-networking module.  It is possible to supply a standard CIDR for `cidr_block` such as "10.0.0.0/8" or "0.0.0.0/0", but alternatively you can pass the key value under "vpcs", which is the name of your VPC.  aws-networking module will then replace the VPC name with the assigned CIDR.  Additionally, `ipam_account_pool` can be set for the `cidr_block` to replace this value with the configured account level pool or parent pool. | `list(object())`
| vpcs.public_subnet_nacl_rules | This will iterate over the configured NACL rules and assign them to the private route table. This is direct configuration of NACL Rules in AWS with support for dynamic names of VPCs in the cidr_block within aws-networking module.  It is possible to supply a standard CIDR  for `cidr_block` such as "10.0.0.0/8" or "0.0.0.0/0", but alternatively you can pass the key value under "vpcs", which is the name of your VPC.  aws-networking module will then replace the VPC name with the assigned CIDR. Additionally, `ipam_account_pool` can be set for the `cidr_block` to replace this value with the configured account level pool or parent pool. | `list(object())`
| vpcs.tgw_config.route_destinations | This will configure routes within the VPC Route Tables to the Transit Gateway. The configured value can be static, such as "0.0.0.0/0", or dynamic, similar to the NACL rules.  When using dynamic, utilize the VPC name you assigned to the VPC under "vpcs".  aws-networking module will replace the VPC name with the assigned CIDR. | `list(string)`
| transit_gw.tgw_is_enabled | Boolean value to indicate that aws-networking should create a Transit Gateway. | `bool`
| transit_gw.tgw_vpc_attach | List of named VPCs to attach to the Transit Gateway. | `list(string)`


## Major Revision Updates

#### Version 1.0 (Initial Release)

1. Support for any number of VPCs.
2. Creation of a dynamic set of public and private subnets.
3. Auto VPC and Subnet CIDR assignments from parent IPAM pool.
4. Route table configuration for HA NAT Gateway (1 Route Table / Subnet).
5. Subnet NACL support with auto shorthand replacement of VPC names to VPC CIDR.
6. A default Security Group that can be used or referenced with parent pool CIDR.
7. Internet Gateway confgiuration.
8. NAT Gateway configuration for public/private and HA support.
9. VPCE Gateway service support for AWS services such as "S3" and "Dyanmodb".
10. Interface Gateway (PrivateLink) support in 2 config modes (public/private).
11. Public Interface Gateway will associate interface gateway with both public and private subnets.
12. Private Interface Gateway will associate interface gateway with private subnets only.
13. Transit Gateway with VPC assignment.
14. Transit Gateway route updates for every route table in the assigned VPC.

## License

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)