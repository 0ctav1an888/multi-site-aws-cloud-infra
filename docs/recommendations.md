# Recommendations Docs
After carefully reviewing this implementation I have identified three critical improvements that can enhance security, reliability and overall performance. This setup provides the right foundation for the system to work just fine, but the flaws of the system can make it vulnerable for external attacks and risk to expose the factory's new IT infrastructure to malicious attacks.

## Issue 1: Security vulnerabilities
The current infrastructure has a few security gaps that canexpose the system to unnecessary risk from external sources.

**Using HTTP instead of HTTPS**
The load balancer only accepts HTTP traffic on port 80 (you can see the this reference here terraform/envs/sandbox/main.tf). Using an HTTPS protocol instead will add that extra layer of security that is needed particularly when hosting an entire organisation's IT infrastructure with external cloud providers such as AWS in this case.

**Too open Security Groups**
SSH access (port 22) is allowed from entire VPC rather than being restricted to specific hosts. This means any compromised server could potentially access other servers via SSH and create some overly open access between databases.

### What I changed
- Restricted SSH access to specific VPC CIDR ranges instead of 0.0.0.0/0 in all groups.
- Added HTTPS port support in ALB security group

These changes are critical to maintain a high level of security for the entire infrastructure to protect inbound and outbound accesss by using a protected protocol such as HTTPS and reducing the amount of permission of connection between servers through the use of SSH protocol.

## Issue 2: Non-resilient system architecture
This current implementation has mentioned has got some strong foundations but each service is coupled and dependent to each other, which means if one component fails it can have an impact on all other components creating a service failure or outage.

**Single NAT**
Each VPC in the terraform implementaiton is using only one NAT gateway. If the AWS availability zone fail, all subnets instances will lose internet access and will not be able to communicate with other AWS services

**Servers using 1 shared availability zone**
Despite having initiated multiple available zones, all servers are deployed to a single availability zone. If that one single availability zone will fail, the entire system will crash causing a domino effect by making all 

**No backup system using disk volumes**
There is no use of backup disk volumes configured with an automated backup system therefore in case of servers failure the data will be lost permanently and impossible to recover. Considering the IT structure will be seeing a stream of sensible data, providing safety around this data with a data recovery strategy will require the setup of a disk volume to back data up (in this case EBS for AWS) will provide the factory with the possibility to recover lost data.

### What I changed
- Changed from using single NAT to implementing NAT gateway per availability zone
- Distributed servers across multiple availability zones
- Implemented AWS EBS volume snapshots and automated backup system configured

With this changes we will further reinforce the reliability of this implementation during any possible disasters. With the implmentation of multiple shared availability zones we will ensure continuous accessibility of systems to the end user and if disruption will occur, a backup system in place will ensure no data will be lost ensuring a smooth recovery.

## Issue 3: No monitoring or logging processes
### The Problem

Currently, there is no monitoring or logging configured for the infrastructure. This creates several blind spots:

**No Visibility into Performance**
You cannot see CPU usage, memory consumption, network traffic, or disk I/O metrics for any servers.

**No Security Logging**
VPC Flow Logs are not enabled, so you cannot detect unusual network traffic patterns, potential security breaches, or troubleshoot connectivity issues.

**No Application Logs**
The load balancer doesn't save access logs, making it impossible to analyze traffic patterns or investigate issues.

**No Alerting**
There are no alarms configured to notify you when problems occur (server failures, unhealthy targets, high CPU usage, etc.).

### What I changed
- Added VPC Flow Logs by adding aws_flow_log resources
- CloudWatch was added and enabled in instances to monitor
- Enabled monitoring and backup for each module in the sandbox environment

## CI processes and tooling recommendations
### Improvement plan

- **CI Quality Assurance** - adding Terraform fmt/validate and ansible-lint commands to the CI pipeline will prevent from merging failed infrastructure components by enforcing correct formatting.
- **Policy and security scans** - implementing policy scanning through the terraform-compliance command and secret scanning tools in the CI process will prevent the utilisation of risky configurations and credential leaks before the infrastructure is deployed.
- **State Locking** - Locking Terraform State with DynamoDB and S3 bucket ensures only one pipeline is applied at the time without conflicting with other team members work. Without a lock the Terraform state can be corrupted and break the entire setup. This ensure safety, consistency and smooth team workflow.
- **Terraform logs retention** - Using the backend functionality of Terraform through S3 buckets you can persist a history of logs for all Terraform outputs including changes, additions and errors. Without a terraform backend there isn't a system to keep trace of logs. This can be achieved by enabling AWS CloudTrail on backend.