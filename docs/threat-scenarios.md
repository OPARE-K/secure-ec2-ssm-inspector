# 🔒 Threat Scenarios & Security Controls – Secure EC2 Web Server with Inspector & SSM

This lab demonstrates how to secure an EC2-based workload using AWS-native services.  
Key threats and their mitigations are documented below.

---

## 1. Direct Host Access via SSH
- **Threat**: Attackers often target SSH with brute-force or stolen keys.  
- **Impact**: Direct compromise of the host, bypassing central controls.  
- **Mitigation**:  
  - No public IP assigned to the instance.  
  - No SSH allowed in Security Groups.  
  - **SSM Session Manager** provides keyless, auditable access.  

---

## 2. Unpatched OS Vulnerabilities
- **Threat**: Attackers exploit outdated kernel packages or unpatched CVEs.  
- **Impact**: Privilege escalation or remote code execution.  
- **Mitigation**:  
  - **Patch Manager** scheduled scans daily (`AWS-RunPatchBaseline`).  
  - (Optional) weekly patch installs.  
- **Evidence**: Screenshots of Patch Compliance before and after applying updates.

---

## 3. Exposed Web Server Application
- **Threat**: Application vulnerabilities (e.g., misconfigurations, outdated nginx).  
- **Impact**: Service disruption, exploitation of known CVEs.  
- **Mitigation**:  
  - **Security Group** allows inbound port 80 **only from the ALB SG**.  
  - ALB serves as the only internet-facing endpoint.  
  - Inspector continuously scans for CVEs.  

---

## 4. Vulnerability Visibility
- **Threat**: Lack of centralized visibility into instance-level CVEs.  
- **Impact**: Undetected risk exposure.  
- **Mitigation**:  
  - **Amazon Inspector v2** enabled for EC2.  
  - Automatically scans packages and reports CVEs in the console.  

---

## ✅ Conclusion
This lab enforces **least privilege**, **zero-SSH posture**, **automated patching**, and **continuous vulnerability detection** using AWS-managed services.  
