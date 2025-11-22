# ISO/IEC 27001 Requirements

## What is ISO/IEC 27001 and why WBF needs to be compliant
The ISO/IEC 27001 is an international standard for Information Security Management which provides a systematic approach to to managing sensible information which remain secure and confidential while still being available when required.

In short, for WBF it means security the infrastructure to ensure external security its maxed against potential threats from malicious sources to ensure the data transmission remains secure. To ensure that you meet the criterias for ISO certification, an audit of the functional and non-functional modules has been carried out to investigate the changes needed to be compliant.

Upon investigating the implementation of this cloud infrastructure I have spotted the following vulnerabilities which are critical to address quickly to ensure compliance with the ISO/IEC 27001 requirements.

## No Audit Logging Tool Enabled (CloudTrail for AWS)
### Explanation:
The current cloud infrastructure for WBF is missing an important element which is crucial for meeting ISO requirements for Information Management. The current infrastructure is missing logging tools such as CloudTrail for AWS to identify changes and who performed them, helping to monitor the overall security of a cloud infrastructure.

### Why it doesn't meet the ISO requirements:
- It requires an organisation to store logs of activity, particularly user admin activity.
- Logs should be retained for a period of time to refer back in case of security incidents.

### What will meet the ISO requirements:
- Enabling a cloud logging / monitoring tool such as CloudTrail for AWS to track every action performed by a user and help detect suspicious activity.

## Unencrypted HTTP Communication
### Explanation:
ISO 27001 obliges businesses to maintain secure communication protocols. An example of using encrypted and secure protocols would be using HTTPS instead of HTTP which is currently not the case in the implementation of this infrastructure for WBF.

### Why it doesn't meet the ISO requirements:
- Using HTTP protocol instead of HTTPS.
- No valid SSL/TLS certificate present.
- It puts an entire cloud infrastructure vulnerable for man in the middle attacks.

### What will meet the ISO requirements:
- Moving the ALB module to HTTPS by implementing an HTTPS listener.
- Create ACM certificate 
- Enforce TLS for stronger cryptography with strong ciphers and auto renewals.

## No Logging and Monitoring 
### Explanation:
When an infrastructure is launched being able to understand its performance in realtime will ensure availability, but most importantly reliability of the infrastructure, which is a key factor for organizations that are relient of this, which is the case for WBF as the infrastructure plays a key role in the IT functions of the organization.. Implementing monitoring tools and agents can add that layer of extra security in ensuring the infrastructure is available and functioning correctly at all times.

### Why it doesn't meet the ISO requirements:
- No activity tracking - all movements in the system should be recorded for incident management.
- No monitoring of the system means all failures and breaches will go undetected.
- Logs must be stored in order to use them as data for incident management.

### What will meet the ISO requirements:
- Installing CloudWatch to the EC2 instances to monitor all actions in realtime in all the servers
- Enabling load balancing logs in the ALB module

## Conclusion  

The current implementation does not meet the ISO/IEC 27001 primarily due few issues that are critical for the security of the newly migrated WBF infrastructure as its now in cloud format. The primary issues preventing the eligibility for the ISO/IEC certification is missing logging and monitoring and communication encryption by using HTTP protocol instead of HTTPS. These gaps will expose the WBF cloud infrastructure to many vulnerabilities and preventing from effective detection and ongoing monitoring ot the system to identify faults. In order to be eligible for ISO/IEC 27001 certification audit logging tools like AWS CloudTrail, enforcing HTTPS protocols through a valid ACM certificate and enabling CloudWatch agents for 