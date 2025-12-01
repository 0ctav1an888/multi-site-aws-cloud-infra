# Infrastructure Register / System Integration

This document is a register for the infrastructure components demonstrating how the Terraform components are deployed. This way there is a location mapped to the existing IP plan. This document helps towards helping auditing process for this Terraform infrastructure.

## Core network componenets
| Component | Site  | CIDR | Location | Inventory | Integrations & dependencies |
| --- | --- | --- | --- | --- | --- |
| VPC | Llanelli / sandbox | 10.10.0.0/16 | modules/vpc via module llanelli in terraform/envs/sandbox/main.tf | terraform (terraform/envs/sandbox/terraform.tfstate) | Public/DMZ/private/management/guest subnets routes to NAT and VPC peering |
| VPC | Cardiff / sandbox | 10.20.0.0/16 | modules/vpc via module cardiff| terraformta | Public/DMZ/private/management/guest subnets routes to NAT and VPC peering |
| NAT | Llanelli / sandbox | Enabled for private subnets | modules/vpc | terraform  | Attached to Llanelli public subnet and referenced by private route tables |
| NAT | Cardiff / sandbox | Enabled for private subnets | modules/vpc | terraform  | Attached to Cardiff public subnet and referenced by private route tables |
| Route Tables | Llanelli / sandbox | Public, DMZ, private, management | modules/vpc outputs consumed in terraform/envs/sandbox/main.tf | terraform | Routes to IGW, NAT, VPC peering used by ALB/ASG/EC2 subnets |
| Route Tables | Cardiff / sandbox | Public, DMZ, private, management | modules/vpc outputs consumed in terraform/envs/sandbox/main.tf | terraform | Routes to IGW, NAT, VPC peering used by ALB/ASG/EC2 subnets |
| VPC Peering | Llanelli - Cardiff / sandbox | aws_vpc_peering_connection.llanelli_cardiff | terraform/envs/sandbox/main.tf | terraform | Routes added for public and private tables in both sites to allow inter-site traffic |

## Access and security
| Component | Site | CIDR | Location | Inventory | Integrations & dependencies |
| --- | --- | --- | --- | --- | --- |
| Security Groups (file, web, developer, DHCP, security/RADIUS, guest Wi-Fi, client VPN) | Llanelli / sandbox | Modules sg_llanelli_* | modules/security_group instantiations in terraform/envs/sandbox/main.tf | terraform | Attached to respective EC2 instances, ALB ENIs, and client VPN endpoints |
| Security Groups (backup, email, web, security/RADIUS, DHCP, guest Wi-Fi, client VPN) | Cardiff / sandbox | Modules sg_cardiff_* | modules/security_group instantiations | terraform | Attached to respective EC2 instances, ALB ENIs, and client VPN endpoints |
| Application Load Balancer | Llanelli / sandbox | module llanelli_alb | modules/alb created in terraform/envs/sandbox/main.tf | terraform | Uses DMZ subnets, ALB SG targets Llanelli web ASG listeners on 80/443 |
| Application Load Balancer | Cardiff / sandbox | module cardiff_alb | modules/alb created in terraform/envs/sandbox/main.tf | terraform | Uses DMZ subnets, ALB SG targets Cardiff web ASG listeners on 80/443 |
| Client VPN Endpoint | Llanelli / sandbox | module llanelli_client_vpn | modules/vpn created in terraform/envs/sandbox/main.tf | terraform certificates created in same file | Uses client VPN SG, management subnet association, CloudWatch log group/streams |
| Client VPN Endpoint | Cardiff / sandbox | module cardiff_client_vpn | modules/vpn created in terraform/envs/sandbox/main.tf | terraform certificates created in same file | Uses client VPN SG, management subnet association, CloudWatch log group/streams |
| TLS/ACM Certificates | Global / sandbox | aws_acm_certificate.client_vpn_server | terraform/envs/sandbox/main.tf | terraform| Issued for VPN endpoint chained to locally signed CA |
| CloudWatch Log Group + Streams | Global / sandbox | /aws/vpn/client with llanelli and cardiff streams | terraform/envs/sandbox/main.tf | terraform | Receives client VPN connection logs for both sites |

## Compute and application
| Component | Site  | CIDR | Location | Inventory | Integrations & dependencies |
| --- | --- | --- | --- | --- | --- |
| EC2 Instances (file, developer, security/RADIUS, DHCP, guest Wi-Fi gateway) | Llanelli / sandbox | Modules llanelli_* in terraform/envs/sandbox/main.tf | modules/compute | terraform | Use respective security groups and subnets from Llanelli VPC |
| EC2 Instances (backup, email, security/RADIUS, DHCP, guest Wi-Fi gateway) | Cardiff / sandbox | Modules cardiff_* in terraform/envs/sandbox/main.tf | modules/compute | terraform | Use respective security groups and subnets from Cardiff VPC |
| Web Auto Scaling Group | Llanelli / sandbox | module llanelli_web_asg | modules/asg | terraform | Targets Llanelli ALB uses DMZ subnets and ALB target group |
| Web Auto Scaling Group | Cardiff / sandbox | module cardiff_web_asg | modules/asg | terraform | Targets Cardiff ALB uses DMZ subnets and ALB target group |

## Backups and monitoring
| Component | Site  | CIDR | Location | Inventory | Integrations & dependencies |
| --- | --- | --- | --- | --- | --- |
| Backup | Llanelli / sandbox | module llanelli_backup | modules/backup in terraform/envs/sandbox/main.tf | terraform | Protects Llanelli EC2 instances and volumes |
| Backup | Cardiff / sandbox | module cardiff_backup | modules/backup | terraform | Protects Cardiff EC2 instances and volumes |
| CloudWatch Alarms | Llanelli / sandbox | module llanelli_alarms | modules/cloudwatch_alarms | terraform | Monitors ASG and metrics can integrate with incident runbooks |
| CloudWatch Alarms | Cardiff / sandbox | module cardiff_alarms | modules/cloudwatch_alarms | terraform | Monitors ASG and metrics can integrate with incident runbooks |

## Process for edits and changes
1. Propose any changes via pull request with ticket and run CI to capture and apply outputs.
2. Note the pipeline ID and identifiers in the relevant table above.
3. After merging changes, update this register to reflect any additions or changes.
4. Review this register consistently to ensure additions/changes align with the terraform infrastructure and the IP plan.
