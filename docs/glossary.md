📖 Glossary of Common Cloud Security Terms
CVE (Common Vulnerabilities and Exposures)

A public catalog of known security flaws in software and hardware, each with a unique ID (e.g., CVE-2024-12345).
Amazon Inspector maps software on EC2 to CVEs to detect vulnerabilities.

CVSS (Common Vulnerability Scoring System)

An industry standard for rating the severity of vulnerabilities (0–10).

0.0 = None

4.0–6.9 = Medium

7.0–8.9 = High

9.0–10.0 = Critical

SSM (AWS Systems Manager)

A service to manage EC2 and other AWS resources securely, without SSH.

Session Manager: Connect to EC2 without keys or open ports.

Patch Manager: Scan and install OS updates automatically.

VPC Endpoint

Private connections between your VPC and AWS services without using the public internet.

Interface Endpoint: Powered by AWS PrivateLink (used here for SSM, EC2Messages, SSMMessages).

Gateway Endpoint: Targeted at specific services like S3 (used here for patch repo access).

Application Load Balancer (ALB)

Distributes incoming web traffic across EC2 instances.
In this project, ALB is the only public entry point, protecting private EC2 hosts.

Security Group (SG)

A virtual firewall controlling inbound/outbound traffic.

ALB SG: allows HTTP (80) from the internet.

EC2 SG: allows HTTP (80) only from the ALB SG.

Amazon Inspector v2

A vulnerability management service. Continuously scans EC2 instances, container images, and Lambda functions against CVE databases.

Amazon GuardDuty (optional, mentioned in Lab 1)

Threat detection service that continuously monitors for malicious activity or unauthorized behavior.

Terraform

Infrastructure-as-Code tool to provision and manage AWS resources declaratively. Keeps infrastructure version-controlled and reproducible.

Patch Baseline

A set of rules in Patch Manager defining which updates should be auto-approved and installed (e.g., approve security patches immediately, others after 7 days).

Session Manager

Part of SSM. Lets you connect to EC2 via browser or CLI without needing SSH keys, open ports, or bastion hosts. Logs can be stored in CloudWatch or S3 for auditing.