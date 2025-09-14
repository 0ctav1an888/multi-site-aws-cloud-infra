# Cloud Architecture Design

## Two VPCs
- vpc_llanelli (Llanelli VPC)
- vpc_cardiff (Cardiff VPC)

## Subnets:
- Public / DMZ (ALB, NAT Gateway)
- Private / App (File Server, Dev Servers, RADIUS, VPN)
- Management (Bastion, Jump Hosts, SSM Endpoints)
- Guest Wi-Fi (Isolated and restricted routing)