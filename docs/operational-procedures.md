# Operational Procedures

This document defines the Operational Procedures and act as the main SOP for managing this AWS Terraform infrastructure for the **Welsh Blanket Factory**. It will link all actions to its respective terraform modules and Ansible roles defined in the `terraform/` and `ansible/` directory and references the register in `docs/integration-system.md` for understanding of the ownership. Each section below refers to the existing paths and locations so that any member can quickly find the element that needs changing or updating.

## 1. Introduction
- **Environment:** All site components and main environment (sandbox) are defined in the `terraform/` directory with configurations, inventories and roles managed by Ansible. Ansible configurations and files can be found in the `ansible/` directory with subdirectories ansible/roles - ansible/playbooks - ansible/inventory and variables managed under ansible/group_vars
- **Ownership:** DevOps and IT manages the infrastructure and automation. Development team should follow these runbooks and guidance for changes that will impact shared services as part of the infrastructure.
- **Change Management:** This document needs to follow the standard update process (see below) and ensure changes are version-controlled with Git.

## 2. Manual Pre-Deployment Checks & CI Deployment Process

**Manual Pre Deployment Checks:**
This part is crucial. It ultimately ensures that we are deploying an IaC free of syntax errors and vulnerabilities such as credentials exposed that could put the entire infrastructure at risk. Ensuring clean coding practices will ensure that we maintain an IaC free of syntax errors which ultimately makes the ongoing maintenance smooth and straighforward with the help of the guidance in this operational handbook.

What the DevOps, Network or IT personnel needs to ensure manually:

- **Verify Modules & Sandbox Quality** Ensure the Terraform modules and main sandbox enviroment syntax is free of errors that could potentially create bugs during deployment, and that all relevant Terraform modules are called correctly in their respective functionality to build the final sandbox environment. This step is crucial to ensure a final smooth deployment.

- **Verify Ansible configurations, inventory and secrets** are up to date and free for syntax errors that could break the CI pipeline - Additionally ensure all the tests are setup correctly and in the right sequence. **Correct Sequence of Playbooks:** `Initial Setup` > `Connectivity Test` > `Security Validation` > `Integration Tests` > `Performance Tests` ensure this is the correct sequence run of the playbooks in the site.yml file.

**CI Pipeline Deployment Process:**
Once the manual checks have been actioned and potential syntax errors and potential bugs have been fixed, and no credentials are exposed. We can launch the `Jenkins` CI pipeline for the final checks, configurations and deployment

- **Validation Stage**: This step will ensure all the modules and are installed correctly and locking in the state of the sandbox through the `terraform init` command in a remote backend, and the infrastructure syntax and structure is valid through a validation check run through `terraform validate` command, and ultimately the `terraform plan` commnand will tell you exaclty what would be created, updated or deleted but it will not deploy the final infrastructure. 

- **Secrets Scanning Stage:** Then the `detect-secrets` package from pip will give a final scan on the secrets for this infrastructure to check if there is any credentials exposed before the configurations from the ansible playbooks will be applied.

- **Ansible Stage**: Once no credentials vulnerabilities are identified this step will run the initial setup, configurations and run all necessary connectivity, performance, security, and integration tests. All tests (playbooks) can be found under the `ansible/playbooks` directory and are bundled in a unique file called `site.yml` which is called in the pipeline step for this process.

- **Final Deployment Stage**: Finally, the last stage of the pipeline will perform the `terraform apply` command to replicate the infrastructure live in AWS.

**Note:** The ansible playbooks for initial setup, configurations and tests are grouped into a unique playbook file called `site.yml` for a more granular approach to testing, the playbooks can be run individually in the `Jenkinsfile` by adjusting the stages structure of the pipeline.

**Post-Deployment Checks:** Confirm configuration register it's accurate and has not changed and reflecting the infrastructure design. Run manual health checks against each module.

**In case of failure:** Revert to prior git commit or if this is a second release, revert back to previous terraform state. Revert the ansible configurations to the last known inventory. **More on this in the next section**


## 3. Backup & Restore Process

**Scope:** Terraform state (remote backend), snapshots for EC2/ASG, database backups, config. files, and logs. For EC2 and ASG modules, the backup plans are defined in the terraform/modules/backup module and instantiated per site in terraform/envs/sandbox/main.tf.

**Storage:** The `Terraform state` is locked in a remote backend which involves `DynamoDB` + `S3` - an encrypted object store with access logging enabled

**Restore Process:**
- Restore the state files first. Then network/access components. Then compute and remaining data layers - this sequence it's important.
- Validate the data integrity and the application functionality post-restoring.

## 4. Metrics, Logging and Alert Response

- **Signals:** `CloudWatch` alarms defined via `terraform/modules/cloudwatch_alarms` provide the default signal set. Metrics collected from CloudWatch include performance data from all AWS services instanciated in the Terraform sandbox. CloudWatch additional will collect logs for applications and system logs for the infrastructure. A key feature for CloudWatch is Alarms. These alarms are set in the infrastructure to trigger when a specific component performans drops below a certain threshold. In the infrastructure alerts are set to trigger when:

    - CPU surpass a certain threshold
    - Status check failed twice
    - Disk usage above a certain threshold
    - High memory usage
    - General unhealthy targets

This is a critical function for DevOps and IT team to continuously monitor the performance of the infrastructure and act upon alerts from CloudWatch promptly.

**Post-Incident Process**: 

1. Capture Incident Timeline
2. Record Remediation Plan
3. Record Follow-Up Actions
4. Update modules, sandbox env., ansible configs if issues are identified.

All these steps need to be recorded in a dedicated `Incident Response Management Registry`. (This is not created for the scope of this assignment due to lack of incidents)

## 5. Security Operations

**Controls to verify regularly:** 
- **Security Groups** - regularly review the individual modules created in `security_group/` directory and how they are instanced in the `terraform/envs/sandbox` environment which 
- **IAM Policy Checks:** - Regularly reviwew the policy and user access management credentials for users.
- **Admin Logs & User Access** - Ultimately, regularly reviewing the admin logs to monitor user actions within the infrastructure will help us identify error, as well as prevent malicious attacks.

## 6. Routine Health & Compliance Checks

**Scheduled Checks:**
- **Health Checks** - Daily at 9am
- **Security Scan** - Daily at 11am
- **Performance Review** - Daily 1pm
- **Logs Review** - Bi-weekly to identify user activity
- **Backup Success Check** - Based on the frequency set of backup process
- **Conformance to IP Plan** - Every time changes to the infrastructure are made such as implementations of new modules.
- **Review User Access Management** - Monthly this will ensure that users have access to their relevant resources without being authorized to make changs to resources they no longer have responsibility to maintain.

**Ownership:**
- **IT Managers:** (User Access Management, Health Checks)
- **DevOps Team:** (Backup Success, Performance Review, IP Plan conformance)
- **Security Team** (Security Scans, User Access Management, Logs Review)

**Note:** Ensure that outcomes a reported in the apposite documents for change management.

## 7. Change Management & Approvals

Every update/change made to the Terraform infrastructure and configuration management tools needs to follow a precise change management process outlined below and ensure that every record in the Change Management Record (not created yet) need 

**Ownership:** Anyone working directly with this infrastructure it's responsible for keeping the Change Management Registry up-to-date.

1. Review the existing Change Management Registry to avoid conflicting changes already requested by other members, approved and merged.
2. Fill in all the key fields in the Change Management Registry for the approval process from the assigned reviewer. This allows the QA member to understand the change required.
4. Once the change has been approved the assignee can go ahead to implement the change and then open a pull request to merge in the codebase.

**Note:** This Operational Procedures document should be reviewed regularly and ensure it matches the new changes in process and management of this infrastructure. 

## 8. References

- `docs/integration-register.md`  | Register for the infrastructure components demonstrating how the Terraform components are deployed.
- `docs/recommendations.md` | for pipeline/tooling improvements and network design verification steps.
- `docs/components-register.md` | Modules documentation.
- `docs/ip-plan` | IP Plan context.

