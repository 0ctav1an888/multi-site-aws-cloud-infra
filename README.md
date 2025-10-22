# Welsh Blanket Factory - Cloud Infrastructure

Terraform infrastructure-as-code for Welsh Blanket Factory's multi-site AWS network deployment.

## Project Overview

This project implements a cloud-based infrastructure for Welsh Blanket Factory with two primary sites (Llanelli and Cardiff) interconnected via VPC peering. The infrastructure is designed to support 8 application servers, load balancing, VPN connectivity, and isolated guest Wi-Fi networks.

### Architecture Highlights

- **Two VPCs**: Llanelli (10.10.0.0/16) and Cardiff (10.20.0.0/16)
- **VPC Peering**: Full bi-directional connectivity between sites
- **Subnet Types**: Public/DMZ, Private/App, Management, Guest Wi-Fi
- **8 Application Servers**: File, Developer, Web, DHCP, Backup, Email, Security servers
- **Load Balancing**: Application Load Balancer for web traffic
- **Security**: Dedicated security groups for each service
- **VPN Support**: Site-to-Site VPN capability

## Prerequisites

- Terraform >= 1.2.0
- AWS CLI configured with appropriate credentials
- AWS Account with sufficient permissions
- AWS Free Tier or appropriate billing setup

## Quick Start

```bash
# Navigate to sandbox environment
cd terraform/envs/sandbox

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply

# Destroy infrastructure
terraform destroy
```

## Directory Structure

```
task_2_project/
├── terraform/
│   ├── backend.tf              # Terraform backend configuration
│   ├── envs/
│   │   └── sandbox/            # Sandbox environment
│   │       ├── main.tf         # Main configuration
│   │       ├── variables.tf    # Variable definitions
│   │       └── outputs.tf      # Output values
│   └── modules/
│       ├── vpc/                # VPC networking module
│       ├── compute/            # EC2 instance module
│       ├── security_group/     # Security group module
│       ├── alb/                # Application Load Balancer module
│       └── vpn/                # Site-to-Site VPN module
├── docs/
│   ├── cloud-design.md         # Architecture design
│   └── ip-plan.md              # IP addressing plan
└── README.md                   # This file
```

## IP Addressing Scheme

### Llanelli Site (10.10.0.0/16)
| Subnet Type | CIDR | Purpose |
|-------------|------|---------|
| VPC | 10.10.0.0/16 | Full VPC range |
| Private/App | 10.10.10.0/24 | Application servers |
| Public/DMZ | 10.10.20.0/24 | Web servers, ALB, NAT Gateway |
| Guest Wi-Fi | 10.10.30.0/24 | Isolated guest network |
| Management | 10.10.254.0/24 | Management and monitoring |

### Cardiff Site (10.20.0.0/16)
| Subnet Type | CIDR | Purpose |
|-------------|------|---------|
| VPC | 10.20.0.0/16 | Full VPC range |
| Private/App | 10.20.10.0/24 | Application servers |
| Public/DMZ | 10.20.20.0/24 | Public-facing services |
| Guest Wi-Fi | 10.20.30.0/24 | Isolated guest network |
| Management | 10.20.254.0/28 | Management and monitoring |

## Deployed Resources

### Llanelli Site
- **VPC**: 10.10.0.0/16
- **Servers**:
  - File Server (t3.small) - Private subnet
  - Developer Server (t3.small) - Private subnet
  - Web Server (t3.micro) - Public subnet with public IP
  - DHCP Server (t3.micro) - Private subnet
- **Load Balancer**: Application Load Balancer for web traffic
- **NAT Gateway**: Internet access for private subnet resources

### Cardiff Site
- **VPC**: 10.20.0.0/16
- **Servers**:
  - Backup Server (t3.small) - Private subnet
  - Email Server (t3.small) - Private subnet
  - Security Server (t3.small) - Private subnet
  - DHCP Server (t3.micro) - Private subnet
- **NAT Gateway**: Internet access for private subnet resources

### Inter-Site Connectivity
- **VPC Peering**: Enables communication between Llanelli and Cardiff
- **Route Tables**: Configured with routes for cross-VPC traffic

## Modules

### VPC Module
Creates complete VPC with subnets, route tables, Internet Gateway, NAT Gateway, and optional VPN.

[See detailed documentation](terraform/modules/vpc/README.md)

### Compute Module
Deploys EC2 instances with configurable settings for various server roles.

[See detailed documentation](terraform/modules/compute/README.md)

### Security Group Module
Creates security groups with dynamic ingress/egress rules.

[See detailed documentation](terraform/modules/security_group/README.md)

### ALB Module
Deploys Application Load Balancer with target groups and health checks.

[See detailed documentation](terraform/modules/alb/README.md)

### VPN Module
Configures Site-to-Site VPN with customer gateway and VPN connection.

[See detailed documentation](terraform/modules/vpn/README.md)

## Security

- All EC2 root volumes encrypted by default
- Security groups with minimal required access
- Guest Wi-Fi networks isolated from internal resources
- Management subnets separated from application traffic
- NAT Gateways for secure outbound internet access

## Outputs

After deployment, Terraform provides:
- VPC IDs and subnet IDs for both sites
- Instance IDs and IP addresses for all servers
- ALB DNS name for web server access
- VPN connection details (if configured)

Access outputs with:
```bash
terraform output
```

## Testing

To validate the infrastructure:

```bash
# Validate Terraform configuration
terraform validate

# Check for formatting issues
terraform fmt -check -recursive

# Generate and review execution plan
terraform plan
```

## Maintenance

### Adding New Resources
1. Create or modify appropriate module
2. Update sandbox/main.tf to instantiate new resources
3. Run terraform plan to preview changes
4. Apply changes with terraform apply

### Updating Existing Resources
1. Modify relevant module or configuration
2. Review changes with terraform plan
3. Apply with terraform apply

## Troubleshooting

### Common Issues

**Issue**: Terraform state lock error
**Solution**: Ensure no other terraform processes are running

**Issue**: AWS credentials not found
**Solution**: Configure AWS CLI with `aws configure`

**Issue**: Resource already exists
**Solution**: Import existing resource or remove from AWS console

## Contributing

1. Create feature branch
2. Make changes
3. Test with terraform plan
4. Commit with meaningful messages
5. Create pull request

## License

Internal use only - Welsh Blanket Factory

## Authors

Infrastructure Team - Welsh Blanket Factory

## Version History

- v1.0.0 - Initial infrastructure deployment
  - Two-site VPC setup with peering
  - Eight application servers deployed
  - Load balancer configured
  - Security groups implemented
  - Guest Wi-Fi networks added
