# Welsh Blanket Factory - Cloud Infrastructure

Complete Infrastructure-as-Code solution with Terraform deployment and Ansible configuration management for Welsh Blanket Factory's multi-site AWS network.

## Project Overview

This project implements a production-ready cloud infrastructure for Welsh Blanket Factory with two primary sites (Llanelli and Cardiff) interconnected via VPC peering. The solution includes both infrastructure provisioning (Terraform) and automated configuration management with comprehensive testing (Ansible).

### Architecture Highlights

- **Two VPCs**: Llanelli (10.10.0.0/16) and Cardiff (10.20.0.0/16)
- **VPC Peering**: Full bi-directional connectivity with configured routes
- **Subnet Types**: Public/DMZ, Private/App, Management, Guest Wi-Fi (isolated)
- **8 Application Servers**: File, Developer, Web, DHCP, Backup, Email, Security servers
- **Static IP Allocation**: Predictable IP addresses for all servers
- **Load Balancing**: Application Load Balancer for web traffic
- **Security**: Dedicated security groups with SSH access for management
- **VPN Support**: Site-to-Site VPN capability
- **Automated Testing**: 5-phase Ansible test suite for validation

## Prerequisites

### Infrastructure Tools
- Terraform >= 1.2.0
- Ansible >= 2.9
- Python 3.8+ with pip
- AWS CLI configured with credentials

### AWS Requirements
- AWS Account with sufficient permissions (EC2, VPC, IAM)
- **SSH Key Pair** created in AWS EC2 (name: `welsh-blanket-factory`)
  - Create via AWS Console: EC2 > Key Pairs > Create key pair
  - Download .pem file to `~/.ssh/welsh-blanket-factory.pem`
  - Set permissions: `chmod 600 ~/.ssh/welsh-blanket-factory.pem`
- AWS Free Tier or appropriate billing setup

### Python Dependencies
```bash
pip install -r ansible/requirements.txt
```
Installs: netaddr, boto3, botocore

## Quick Start

### 1. Initial Setup

```bash
# Clone repository
git clone <repository-url>
cd task_2_project

# Install Python dependencies
pip install -r ansible/requirements.txt

# Install Ansible collections
cd ansible
ansible-galaxy collection install -r requirements.yml
cd ..
```

### 2. Deploy Infrastructure with Terraform

```bash
# Navigate to sandbox environment
cd terraform/envs/sandbox

# Initialize Terraform
terraform init

# Review planned changes (approx 45+ resources)
terraform plan

# Deploy infrastructure
terraform apply

# Note the outputs (server IPs, ALB DNS, etc.)
terraform output
```

### 3. Configure and Test with Ansible

```bash
# Navigate to Ansible directory
cd ../../ansible

# Run complete test suite (all 5 phases)
ansible-playbook playbooks/site.yml

# Or run individual test phases:
ansible-playbook playbooks/initial-setup.yml      # Server configuration
ansible-playbook playbooks/connectivity-test.yml  # Network connectivity
ansible-playbook playbooks/security-validation.yml # Security checks
ansible-playbook playbooks/integration-test.yml   # Integration tests
ansible-playbook playbooks/performance-test.yml   # Performance metrics

# View test reports (generated on each server)
# Reports location: /var/log/ansible-tests/
# Local reports: ./test-reports/
```

### 4. Cleanup

```bash
# Destroy infrastructure
cd terraform/envs/sandbox
terraform destroy
```

## Directory Structure

```
task_2_project/
├── terraform/                     # Infrastructure as Code
│   ├── backend.tf                # Terraform backend configuration
│   ├── envs/
│   │   └── sandbox/              # Sandbox environment
│   │       ├── main.tf           # Main configuration (VPCs, compute, ALB)
│   │       ├── variables.tf      # Variable definitions
│   │       └── outputs.tf        # Output values
│   └── modules/
│       ├── vpc/                  # VPC networking module (4 subnet types)
│       ├── compute/              # EC2 instance module (static IPs)
│       ├── security_group/       # Security group module (dynamic rules)
│       ├── alb/                  # Application Load Balancer module
│       └── vpn/                  # Site-to-Site VPN module
├── ansible/                       # Configuration Management & Testing
│   ├── ansible.cfg               # Ansible configuration
│   ├── requirements.yml          # Ansible collections (amazon.aws, etc.)
│   ├── requirements.txt          # Python dependencies (netaddr, boto3)
│   ├── inventory/
│   │   ├── aws_ec2.yml          # Dynamic AWS inventory plugin
│   │   └── hosts.yml            # Static inventory (IP mappings)
│   ├── group_vars/
│   │   ├── all.yml              # Global variables
│   │   ├── llanelli.yml         # Llanelli site config
│   │   └── cardiff.yml          # Cardiff site config
│   ├── roles/
│   │   └── common/              # Common server configuration role
│   └── playbooks/
│       ├── initial-setup.yml     # Initial configuration
│       ├── connectivity-test.yml # Network testing
│       ├── security-validation.yml # Security checks
│       ├── integration-test.yml  # Integration tests
│       ├── performance-test.yml  # Performance tests
│       └── site.yml              # Master playbook (all phases)
├── docs/
│   ├── cloud-design.md           # Architecture design
│   └── ip-plan.md                # IP addressing plan
├── INTEGRATION_FIXES.md          # Terraform/Ansible integration fixes
└── README.md                     # This file
```

## IP Addressing Scheme

### Llanelli Site (10.10.0.0/16)
| Subnet Type | CIDR | Purpose | Static IPs Assigned |
|-------------|------|---------|---------------------|
| VPC | 10.10.0.0/16 | Full VPC range | - |
| Private/App | 10.10.10.0/24 | Application servers | .10, .11, .12 |
| Public/DMZ | 10.10.20.0/24 | Web servers, ALB, NAT Gateway | .10 |
| Guest Wi-Fi | 10.10.30.0/24 | Isolated guest network | - |
| Management | 10.10.254.0/28 | Management and monitoring | - |

**Llanelli Server IPs:**
- File Server: 10.10.10.10
- Developer Server: 10.10.10.11
- DHCP Server: 10.10.10.12
- Web Server: 10.10.20.10 (+ Public IP)

### Cardiff Site (10.20.0.0/16)
| Subnet Type | CIDR | Purpose | Static IPs Assigned |
|-------------|------|---------|---------------------|
| VPC | 10.20.0.0/16 | Full VPC range | - |
| Private/App | 10.20.10.0/24 | Application servers | .10, .11, .12, .13 |
| Public/DMZ | 10.20.20.0/24 | Public-facing services | - |
| Guest Wi-Fi | 10.20.30.0/24 | Isolated guest network | - |
| Management | 10.20.254.0/28 | Management and monitoring | - |

**Cardiff Server IPs:**
- Backup Server: 10.20.10.10
- Email Server: 10.20.10.11
- Security Server: 10.20.10.12
- DHCP Server: 10.20.10.13

## Deployed Resources

### Llanelli Site
- **VPC**: 10.10.0.0/16 with 4 subnets (Private, Public, Guest, Management)
- **Servers** (all with SSH key `welsh-blanket-factory`):
  - File Server (t3.small) - 10.10.10.10 - Private subnet - SMB/NFS
  - Developer Server (t3.small) - 10.10.10.11 - Private subnet - Dev ports
  - Web Server (t3.micro) - 10.10.20.10 - Public subnet + Public IP - HTTP/HTTPS
  - DHCP Server (t3.micro) - 10.10.10.12 - Private subnet - DHCP services
- **Load Balancer**: Application Load Balancer targeting web server on port 80
- **NAT Gateway**: Public subnet - Internet access for private resources
- **Security Groups**: 5 groups with SSH access from both VPCs

### Cardiff Site
- **VPC**: 10.20.0.0/16 with 4 subnets (Private, Public, Guest, Management)
- **Servers** (all with SSH key `welsh-blanket-factory`):
  - Backup Server (t3.small) - 10.20.10.10 - Private subnet - Backup services
  - Email Server (t3.small) - 10.20.10.11 - Private subnet - SMTP/IMAP
  - Security Server (t3.small) - 10.20.10.12 - Private subnet - Security monitoring
  - DHCP Server (t3.micro) - 10.20.10.13 - Private subnet - DHCP services
- **NAT Gateway**: Public subnet - Internet access for private resources
- **Security Groups**: 4 groups with SSH access from both VPCs

### Inter-Site Connectivity
- **VPC Peering**: Active peering connection between VPCs
- **Route Tables**: Bidirectional routes configured
  - Llanelli private/public → Cardiff (10.20.0.0/16)
  - Cardiff private/public → Llanelli (10.10.0.0/16)
- **Cross-Site Access**: All servers can communicate via VPC peering

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

## Configuration Management (Ansible)

### Overview
Ansible provides automated configuration management and comprehensive testing across all 8 servers. The implementation includes both dynamic AWS EC2 inventory and static IP-based inventory.

### Test Suite Phases

1. **Initial Setup** - System configuration, packages, timezone, NTP, hostname
2. **Connectivity Tests** - Internet, DNS, intra-site, cross-site VPC peering
3. **Security Validation** - SSH, HTTP/HTTPS ports, SELinux, security updates
4. **Integration Tests** - VPC peering, file/web servers, subnet isolation, NAT Gateway
5. **Performance Tests** - Latency metrics, system load, network throughput

### Running Tests

```bash
cd ansible

# Complete test suite (recommended)
ansible-playbook playbooks/site.yml

# Individual phases
ansible-playbook playbooks/connectivity-test.yml
ansible-playbook playbooks/integration-test.yml

# Target specific site
ansible-playbook playbooks/site.yml --limit llanelli
ansible-playbook playbooks/site.yml --limit cardiff

# Target specific server
ansible-playbook playbooks/site.yml --limit llanelli-web-server
```

### Test Reports
- **Remote**: `/var/log/ansible-tests/` on each server
- **Local**: `./test-reports/[server-name]/` (fetched by site.yml)

### Inventory Options

**Dynamic Inventory** (Recommended for production):
- Auto-discovers EC2 instances via AWS API
- Groups by Site and Role tags
- Always up-to-date with infrastructure

**Static Inventory** (Useful for development):
- Hardcoded IP addresses matching Terraform
- Works without AWS credentials
- Faster for testing

## Security

- **Encryption**: All EC2 root volumes encrypted by default (EBS encryption)
- **SSH Access**: Configured on all security groups (port 22 from VPC CIDRs)
- **SSH Keys**: Uses AWS EC2 key pair `welsh-blanket-factory`
- **Security Groups**: Minimal required access per service role
  - File server: SSH, SMB (445), NFS (2049)
  - Web server: SSH, HTTP (80), HTTPS (443)
  - Email server: SSH, SMTP (25, 587), IMAP (143, 993)
  - Developer server: SSH, Dev ports (3000-9000)
  - Others: SSH + service-specific ports
- **Network Isolation**:
  - Guest Wi-Fi networks isolated from private subnets
  - Management subnets separated from application traffic
  - Private subnets have no direct internet access
- **NAT Gateways**: Secure outbound internet access for private resources
- **Cross-VPC Traffic**: Controlled via security group rules and route tables

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

## Testing & Validation

### Terraform Validation

```bash
cd terraform/envs/sandbox

# Validate configuration syntax
terraform validate

# Check formatting
terraform fmt -check -recursive

# Generate execution plan
terraform plan

# Verify outputs after deployment
terraform output
```

### Ansible Testing

```bash
cd ansible

# Test dynamic inventory
ansible-inventory -i inventory/aws_ec2.yml --list
ansible-inventory -i inventory/aws_ec2.yml --graph

# Test connectivity to all hosts
ansible all -m ping

# Run complete test suite
ansible-playbook playbooks/site.yml

# Dry run (check mode)
ansible-playbook playbooks/site.yml --check
```

### Integration Verification

See [INTEGRATION_FIXES.md](INTEGRATION_FIXES.md) for comprehensive integration testing between Terraform and Ansible, including:
- SSH connectivity validation
- IP address matching verification
- Dynamic inventory group validation
- Cross-site VPC peering tests

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

### Terraform Issues

**Issue**: Terraform state lock error
**Solution**: Ensure no other terraform processes are running, or force unlock with `terraform force-unlock <lock-id>`

**Issue**: AWS credentials not found
**Solution**: Configure AWS CLI with `aws configure` or set environment variables

**Issue**: Resource already exists
**Solution**: Import existing resource with `terraform import` or remove from AWS console

**Issue**: SSH key pair not found
**Solution**: Create key pair in AWS EC2 console named `welsh-blanket-factory`

### Ansible Issues

**Issue**: Ansible cannot connect to hosts
**Solution**:
- Ensure infrastructure is deployed (`terraform apply`)
- Verify SSH key exists at `~/.ssh/welsh-blanket-factory.pem`
- Check key permissions: `chmod 600 ~/.ssh/welsh-blanket-factory.pem`
- Verify security groups allow SSH (port 22)

**Issue**: Dynamic inventory returns no hosts
**Solution**:
- Verify AWS credentials: `aws ec2 describe-instances`
- Check instances are running and tagged correctly (Environment: sandbox)
- Test inventory: `ansible-inventory -i inventory/aws_ec2.yml --graph`

**Issue**: `ipaddr` filter not found
**Solution**: Install netaddr: `pip install -r ansible/requirements.txt`

**Issue**: Playbook fails with "undefined variable 'groups'"
**Solution**: Verify inventory group names match (llanelli, cardiff without prefixes)

### Network Issues

**Issue**: Cannot ping between Llanelli and Cardiff
**Solution**:
- Verify VPC peering connection is active
- Check route tables have peer VPC routes configured
- Verify security groups allow ICMP or required ports

**Issue**: Private subnet instances cannot access internet
**Solution**:
- Verify NAT Gateway is deployed and running
- Check private subnet route table has 0.0.0.0/0 → NAT Gateway
- Verify security groups allow outbound traffic

**Issue**: Cannot SSH to instances
**Solution**:
- For public subnet: Check instance has public IP
- For private subnet: Use bastion host or VPN
- Verify security group allows SSH from your IP
- Check NACL rules (default should allow all)

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

## Important Notes

### SSH Key Pair
Before deployment, you **MUST** create an SSH key pair in AWS:
1. Go to AWS Console > EC2 > Key Pairs
2. Create key pair named: `welsh-blanket-factory`
3. Download .pem file to `~/.ssh/`
4. Set permissions: `chmod 600 ~/.ssh/welsh-blanket-factory.pem`

### Static IP Addresses
All servers use static IP allocation. If you need to change IPs:
1. Update `terraform/envs/sandbox/main.tf` (private_ip parameters)
2. Update `ansible/inventory/hosts.yml` (ansible_host values)
3. Run `terraform apply` to update infrastructure

### Cost Considerations
This deployment creates:
- 2 VPCs (no charge)
- 8 EC2 instances (charges apply - t3.small and t3.micro)
- 2 NAT Gateways ($0.045/hour each + data transfer)
- 1 Application Load Balancer ($0.0225/hour + LCU charges)
- VPC Peering (no charge for data transfer within same region)

Estimated monthly cost (us-east-1): $150-200 depending on usage

### Clean Up
To avoid charges, destroy infrastructure when not in use:
```bash
cd terraform/envs/sandbox
terraform destroy
```

## Additional Documentation

- [INTEGRATION_FIXES.md](INTEGRATION_FIXES.md) - Terraform/Ansible integration fixes and validation
- [terraform/modules/vpc/README.md](terraform/modules/vpc/README.md) - VPC module documentation
- [terraform/modules/compute/README.md](terraform/modules/compute/README.md) - Compute module documentation
- [terraform/modules/security_group/README.md](terraform/modules/security_group/README.md) - Security group documentation
- [terraform/modules/alb/README.md](terraform/modules/alb/README.md) - ALB module documentation
- [terraform/modules/vpn/README.md](terraform/modules/vpn/README.md) - VPN module documentation
- [docs/cloud-design.md](docs/cloud-design.md) - Architecture design document
- [docs/ip-plan.md](docs/ip-plan.md) - IP addressing plan

## Version History

### v1.0.0 (2025-10-22) - Production Release
- ✅ Complete Terraform infrastructure deployment
  - Two-site VPC setup (Llanelli + Cardiff) with VPC peering
  - Eight application servers with static IPs
  - Application Load Balancer for Llanelli web server
  - Nine security groups with SSH access
  - Four subnet types per VPC (Private, Public, Guest, Management)
  - VPC peering routes configured bidirectionally
- ✅ Complete Ansible configuration management
  - Common role for server configuration
  - 5-phase testing playbook suite
  - Dynamic AWS EC2 inventory plugin
  - Static inventory with IP mappings
  - Comprehensive test reporting
- ✅ Integration fixes (11 issues resolved)
  - SSH connectivity enabled on all servers
  - Dynamic inventory group names aligned
  - Static IP addresses synchronized
  - Management subnet CIDR corrected (/28)
  - /etc/hosts configuration fixed
  - Python dependencies documented
  - All Terraform/Ansible integration validated
