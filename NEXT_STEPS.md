# Next Steps - Infrastructure Deployment Guide

## 🚀 Quick Start

### Step 1: Review and Customize Configuration

Before deploying, update these values in `terraform/envs/sandbox/main.tf`:

#### Update Email Addresses for Alarms
```hcl
# Lines 631-633 (Llanelli) and 669-671 (Cardiff)
email_endpoints = [
  "your-actual-email@welshblanketfactory.com"  # Replace with real email
]
```

#### Update S3 Bucket Name (Must Be Globally Unique)
```hcl
# Line 571
access_logs_bucket_name = "llanelli-alb-logs-sandbox-UNIQUEID"  # Add unique suffix
```

---

### Step 2: Run Terraform Plan

```bash
cd terraform/envs/sandbox

# Initialize if not already done
terraform init

# Review the changes
terraform plan

# Save the plan for review
terraform plan -out=tfplan
```

**Expected resources to be created:**
- ~30-40 new resources (NAT gateways, flow logs, backup plans, alarms, etc.)
- 0 resources to be destroyed (all changes are additive)
- Several resources to be modified (instances getting new tags, route tables)

---

### Step 3: Deploy the Infrastructure

```bash
# Apply the saved plan
terraform apply tfplan

# OR apply directly (will prompt for confirmation)
terraform apply
```

**Deployment time:** Approximately 5-10 minutes

---

### Step 4: Confirm SNS Email Subscriptions

After deployment, check your email inbox:

1. You'll receive **2 subscription confirmation emails** (one for Llanelli, one for Cardiff)
2. Click the "Confirm subscription" link in each email
3. Without confirmation, you won't receive alarm notifications!

---

### Step 5: Verify Deployment

#### Check VPC Flow Logs
```bash
# Verify flow logs are enabled
aws ec2 describe-flow-logs --region eu-west-2

# Check CloudWatch log groups
aws logs describe-log-groups --region eu-west-2 --log-group-name-prefix "/aws/vpc/flowlogs"
```

#### Check Backup Plans
```bash
# List backup plans
aws backup list-backup-plans --region eu-west-2

# Verify backup selections
aws backup list-backup-selections --backup-plan-id <plan-id> --region eu-west-2
```

#### Check CloudWatch Alarms
```bash
# List all alarms
aws cloudwatch describe-alarms --region eu-west-2

# Check alarm status
aws cloudwatch describe-alarms --state-value ALARM --region eu-west-2
```

#### Check NAT Gateways
```bash
# Verify multiple NAT gateways per VPC
aws ec2 describe-nat-gateways --region eu-west-2 --filter "Name=state,Values=available"
```

---

## 🧪 Testing Recommendations

### Test Backup Recovery

1. **Wait for first backup to complete** (scheduled for 2 AM UTC)
2. **Verify backup in AWS Console:**
   - AWS Backup → Backup vaults → Select vault → Recovery points
3. **Test restore procedure:**
   - Select a recovery point
   - Choose "Restore"
   - Follow restore wizard to create test instance

### Test CloudWatch Alarms

1. **Trigger CPU alarm** (optional):
   ```bash
   # SSH to an instance and run stress test
   sudo yum install -y stress
   stress --cpu 8 --timeout 300s
   ```
2. **Verify alarm state:**
   - CloudWatch → Alarms → Check alarm status
   - Check email for notification (if SNS confirmed)

### Test VPC Flow Logs

1. **Generate some traffic:**
   ```bash
   # SSH to instances and generate network activity
   curl http://example.com
   ```
2. **Query flow logs:**
   - CloudWatch → Logs → Log groups → `/aws/vpc/flowlogs/llanelli`
   - Verify log entries appear

---

## 📊 Monitoring Dashboard Setup (Optional)

Create a CloudWatch Dashboard for centralized monitoring:

```bash
# Use AWS Console
1. CloudWatch → Dashboards → Create dashboard
2. Add widgets for:
   - EC2 CPU utilization (all instances)
   - ALB request count
   - NAT gateway bytes processed
   - Backup job status
   - VPC Flow Logs insights
```

---

## 🔧 Troubleshooting

### Issue: "Bucket already exists"

**Problem:** S3 bucket names must be globally unique

**Solution:**
```hcl
# Update in terraform/envs/sandbox/main.tf
access_logs_bucket_name = "llanelli-alb-logs-sandbox-${random_id.bucket_suffix.hex}"

# Add random suffix resource
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

### Issue: "Email not receiving alarms"

**Problem:** SNS subscription not confirmed

**Solution:**
1. Check spam folder for confirmation email
2. Verify subscription in AWS Console:
   - SNS → Subscriptions → Check status
3. If needed, re-subscribe manually in AWS Console

### Issue: "BackupSelection failed - no resources found"

**Problem:** No instances have `Backup=true` tag yet

**Solution:**
- Wait for Terraform to apply tags to instances
- Verify tags in EC2 console
- Backup jobs will start automatically at scheduled time

---

## 💰 Cost Monitoring

### View Cost Breakdown

```bash
# Enable Cost Explorer in AWS Console
AWS Billing → Cost Explorer → Enable

# Create cost allocation tags
AWS Billing → Cost allocation tags → Activate tags:
- Site (Llanelli, Cardiff)
- Environment (sandbox)
- Role (file-server, web-server, etc.)
```

### Expected Monthly Costs

| Service | Approximate Cost |
|---------|------------------|
| NAT Gateways (2) | $64 |
| VPC Flow Logs | $20-40 |
| CloudWatch Monitoring | $12.60 |
| CloudWatch Alarms | $3 |
| AWS Backup (Snapshots) | $25 |
| S3 (ALB Logs) | $1-5 |
| **Total** | **~$125-150** |

---

## 📈 Optimization Opportunities

### Reduce Costs

1. **VPC Flow Logs:**
   ```hcl
   flow_logs_retention_days = 3  # Reduce from 7 days
   flow_logs_traffic_type = "REJECT"  # Only log rejected traffic
   ```

2. **Disable monitoring on less critical instances:**
   ```hcl
   # DHCP servers don't need detailed monitoring
   monitoring = false
   ```

3. **Adjust backup retention:**
   ```hcl
   retention_days = 7  # Reduce from 30 days
   enable_weekly_backup = false  # Disable weekly backups
   ```

### Increase Reliability

1. **Enable additional monitoring:**
   ```hcl
   enable_disk_monitoring = true    # Requires CloudWatch Agent
   enable_memory_monitoring = true  # Requires CloudWatch Agent
   ```

2. **Reduce alarm thresholds:**
   ```hcl
   cpu_threshold = 70  # More sensitive (from 80)
   response_time_threshold = 1.0  # Faster response requirement (from 2.0)
   ```

---

## 🔄 Phase 1.2: Multi-AZ Distribution (Future Work)

To implement server distribution across multiple availability zones:

### 1. Update IP Plan

Add second AZ subnets in `terraform/envs/sandbox/variables.tf`:

```hcl
# Llanelli (currently only AZ 0)
llanelli_private_subnets = ["10.10.10.0/24", "10.10.11.0/24"]  # Add second subnet
llanelli_public_subnets  = ["10.10.20.0/24", "10.10.21.0/24"]  # Add second subnet

# Cardiff (currently only AZ 0)
cardiff_private_subnets = ["10.20.10.0/24", "10.20.11.0/24"]   # Add second subnet
cardiff_public_subnets  = ["10.20.20.0/24", "10.20.21.0/24"]   # Add second subnet
```

### 2. Distribute Servers

Example for distributing web servers across AZs:

```hcl
locals {
  web_server_azs = [0, 1]  # Deploy to both AZs
}

module "llanelli_web_server" {
  source = "../../modules/compute"
  count  = 2  # One per AZ

  name          = "llanelli-web-server-${count.index + 1}"
  subnet_id     = module.llanelli.public_subnet_ids[count.index]
  # ... rest of configuration
}

# Update ALB to use both instances
module "llanelli_alb" {
  # ...
  target_ids = module.llanelli_web_server[*].instance_id
}
```

---

## 📞 Support & Documentation

- **Implementation Details:** See `IMPLEMENTATION_SUMMARY.md`
- **Original Plan:** See `docs/implementation-plan.md`
- **Architecture Docs:** See `docs/components-docs.md`
- **Terraform Docs:** Run `terraform-docs markdown . > README.md` in each module directory

---

## ✅ Post-Deployment Checklist

- [ ] Terraform apply completed successfully
- [ ] SNS email subscriptions confirmed (both Llanelli and Cardiff)
- [ ] VPC Flow Logs appearing in CloudWatch
- [ ] First backup scheduled (check after 2 AM UTC)
- [ ] CloudWatch alarms in "OK" state
- [ ] NAT gateways active in both AZs
- [ ] ALB access logs appearing in S3
- [ ] Cost monitoring enabled
- [ ] Team notified of new alarm email addresses
- [ ] Documentation updated with actual resource IDs

---

## 🎯 Success Criteria

✅ All infrastructure deployed without errors
✅ No service disruption during deployment
✅ All monitoring and backup systems operational
✅ Team receiving alarm notifications
✅ Cost within expected budget (~$125-150/month)
✅ Zero single points of failure in network layer

---

Good luck with the deployment! 🚀
