# Integration System Configuration Register

This register records the integrated infrastructure components deployed via Terraform so they can be audited, traced to their source of truth, and mapped to the existing IP plan. Use it as the CMDB-style record the tutor requested.

## How this register is maintained
- **Source of truth:** All components are defined in Terraform modules under `terraform/modules/*` and instantiated in `terraform/envs/sandbox/main.tf`. State is stored in the local file `terraform/envs/sandbox/terraform.tfstate` (or the configured backend when promoted).
- **Change tracking:** Updates are recorded through git history and CI artifacts. Each change should reference the pipeline run ID and git commit in this document when relevant (e.g., when IDs/ARNs rotate).
- **Updates:** When a component is added, removed, or materially changed, add or update an entry below with identifiers (name/ARN/hostname), dependencies, and site/environment scope. Cross-link to the IP ranges in `docs/ip-plan.md` for location context.

## Core networking
| Component | Site / Environment | Identifier (name or CIDR) | Source of truth | State / inventory | Integrations & dependencies |
| --- | --- | --- | --- | --- | --- |
| VPC | Llanelli / sandbox | `10.10.0.0/16` | `modules/vpc` via `module "llanelli"` in `terraform/envs/sandbox/main.tf` | Terraform state (`terraform/envs/sandbox/terraform.tfstate`) | Public/DMZ/private/management/guest subnets; routes to NAT and VPC peering |
| VPC | Cardiff / sandbox | `10.20.0.0/16` | `modules/vpc` via `module "cardiff"` | Terraform state | Public/DMZ/private/management/guest subnets; routes to NAT and VPC peering |
| NAT Gateway | Llanelli / sandbox | Enabled for private subnets | `modules/vpc` (flag `enable_nat=true`) | Terraform state | Attached to Llanelli public subnet and referenced by private route tables |
| NAT Gateway | Cardiff / sandbox | Enabled for private subnets | `modules/vpc` (flag `enable_nat=true`) | Terraform state | Attached to Cardiff public subnet and referenced by private route tables |
| Route Tables | Llanelli / sandbox | Public, DMZ, private, management | `modules/vpc` outputs consumed in `terraform/envs/sandbox/main.tf` | Terraform state | Routes to IGW, NAT, VPC peering; used by ALB/ASG/EC2 subnets |
| Route Tables | Cardiff / sandbox | Public, DMZ, private, management | `modules/vpc` outputs consumed in `terraform/envs/sandbox/main.tf` | Terraform state | Routes to IGW, NAT, VPC peering; used by ALB/ASG/EC2 subnets |
| VPC Peering | Llanelli ↔ Cardiff / sandbox | `aws_vpc_peering_connection.llanelli_cardiff` | `terraform/envs/sandbox/main.tf` | Terraform state | Routes added for public and private tables in both sites to allow inter-site traffic |

## Edge, access, and security
| Component | Site / Environment | Identifier | Source of truth | State / inventory | Integrations & dependencies |
| --- | --- | --- | --- | --- | --- |
| Security Groups (file, web, developer, DHCP, security/RADIUS, guest Wi-Fi, client VPN) | Llanelli / sandbox | Modules `sg_llanelli_*` | `modules/security_group` instantiations in `terraform/envs/sandbox/main.tf` | Terraform state | Attached to respective EC2 instances, ALB ENIs, and client VPN endpoints |
| Security Groups (backup, email, web, security/RADIUS, DHCP, guest Wi-Fi, client VPN) | Cardiff / sandbox | Modules `sg_cardiff_*` | `modules/security_group` instantiations | Terraform state | Attached to respective EC2 instances, ALB ENIs, and client VPN endpoints |
| Application Load Balancer | Llanelli / sandbox | `module "llanelli_alb"` | `modules/alb` instantiated in `terraform/envs/sandbox/main.tf` | Terraform state | Uses DMZ subnets, ALB SG; targets Llanelli web ASG; listeners on 80/443 |
| Application Load Balancer | Cardiff / sandbox | `module "cardiff_alb"` | `modules/alb` instantiated in `terraform/envs/sandbox/main.tf` | Terraform state | Uses DMZ subnets, ALB SG; targets Cardiff web ASG; listeners on 80/443 |
| Client VPN Endpoint | Llanelli / sandbox | `module "llanelli_client_vpn"` | `modules/vpn` instantiated in `terraform/envs/sandbox/main.tf` | Terraform state; certificates minted in same file | Uses client VPN SG, management subnet association, CloudWatch log group/streams |
| Client VPN Endpoint | Cardiff / sandbox | `module "cardiff_client_vpn"` | `modules/vpn` instantiated in `terraform/envs/sandbox/main.tf` | Terraform state; certificates minted in same file | Uses client VPN SG, management subnet association, CloudWatch log group/streams |
| TLS/ACM Certificates | Global / sandbox | `aws_acm_certificate.client_vpn_server` | `terraform/envs/sandbox/main.tf` | Terraform state | Issued for VPN endpoint; chained to locally signed CA |
| CloudWatch Log Group + Streams | Global / sandbox | `/aws/vpn/client` with `llanelli` and `cardiff` streams | `terraform/envs/sandbox/main.tf` | Terraform state | Receives client VPN connection logs for both sites |

## Compute and application delivery
| Component | Site / Environment | Identifier | Source of truth | State / inventory | Integrations & dependencies |
| --- | --- | --- | --- | --- | --- |
| EC2 Instances (file, developer, security/RADIUS, DHCP, guest Wi-Fi gateway) | Llanelli / sandbox | Modules `llanelli_*` in `terraform/envs/sandbox/main.tf` | `modules/compute` | Terraform state | Use respective security groups and subnets from Llanelli VPC |
| EC2 Instances (backup, email, security/RADIUS, DHCP, guest Wi-Fi gateway) | Cardiff / sandbox | Modules `cardiff_*` in `terraform/envs/sandbox/main.tf` | `modules/compute` | Terraform state | Use respective security groups and subnets from Cardiff VPC |
| Web Auto Scaling Group | Llanelli / sandbox | `module "llanelli_web_asg"` | `modules/asg` | Terraform state | Targets Llanelli ALB; uses DMZ subnets and ALB target group |
| Web Auto Scaling Group | Cardiff / sandbox | `module "cardiff_web_asg"` | `modules/asg` | Terraform state | Targets Cardiff ALB; uses DMZ subnets and ALB target group |

## Resilience, backups, and observability
| Component | Site / Environment | Identifier | Source of truth | State / inventory | Integrations & dependencies |
| --- | --- | --- | --- | --- | --- |
| Backup Plans & Vault | Llanelli / sandbox | `module "llanelli_backup"` | `modules/backup` in `terraform/envs/sandbox/main.tf` | Terraform state | Protects Llanelli EC2 instances and volumes |
| Backup Plans & Vault | Cardiff / sandbox | `module "cardiff_backup"` | `modules/backup` | Terraform state | Protects Cardiff EC2 instances and volumes |
| CloudWatch Alarms | Llanelli / sandbox | `module "llanelli_alarms"` | `modules/cloudwatch_alarms` | Terraform state | Monitors ASG and instance metrics; can integrate with incident runbooks |
| CloudWatch Alarms | Cardiff / sandbox | `module "cardiff_alarms"` | `modules/cloudwatch_alarms` | Terraform state | Monitors ASG and instance metrics; can integrate with incident runbooks |

## Update and audit workflow
1. Propose changes via PR with linked ticket; run CI to capture plan/apply outputs.
2. When applying, note the pipeline run ID and resulting resource identifiers (ARNs, DNS names) in the relevant table row above.
3. After merge, update this register to reflect any new components, identifier rotations, or dependency changes.
4. Review this register quarterly to ensure entries align with Terraform state and the IP ranges defined in `docs/ip-plan.md`.
