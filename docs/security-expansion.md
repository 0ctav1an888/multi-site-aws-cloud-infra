# Security Expansion Summary

## DMZ & Network Controls
- Added dedicated DMZ subnet lists to the VPC module with isolated route tables and ACLs for Llanelli and Cardiff.
- Guest Wi-Fi subnets now have restrictive ACLs blocking RFC1918 ranges to keep visitors off the corporate LAN.
- Terraform variables reflect the new subnet layout and IP plan updates.

## Web Tier High Availability
- Single web instances replaced with ASG-backed pools in the DMZ; each site now has its own ALB.
- Route53 health checks and failover records ensure traffic falls back to Cardiff if Llanelli degrades.
- ALB module enhanced to forward to ASG-managed target groups and emit ARN suffixes for monitoring/scaling.

## RADIUS & Access Management
- Llanelli gained a security server twin with shared FreeRADIUS automation, including templated `clients.conf`.
- Ansible `radius` role provisions packages, secrets, and keeps radiusd running on both security servers.
- Security groups now expose UDP/1812-1813 internally only, aligning VPN, Wi-Fi, and device auth flows.

## Home Worker VPN
- Terraform VPN module extended with optional Client VPN resources, log configuration, and outputs.
- Per-site client VPN modules associate with management subnets, push VPC routes, and log to CloudWatch.
- Base client VPN configs & CA certs are exported to `docs/vpn` for downstream automation.

## Guest Wi-Fi Gateways
- Guest Wi-Fi gateways deployed to the new guest subnets with tight SGs allowing only mgmt + HTTP/S egress.
- Ansible `guest_wifi` role enforces firewall isolation and documents captive portal policy.

## Automation & Tooling
- Initial setup play now conditionally runs `radius`, `web`, and `guest_wifi` roles based on host role tags.
- Security validation playbook produces a branded VPN profile via localhost tasks for distribution.
- Connectivity tests verify guest Wi-Fi isolation alongside existing intra/inter-site checks.
