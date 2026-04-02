# Security Incident Response Playbook

## Document Control

| Field | Value |
|-------|-------|
| **Document ID** | IR-PLAY-002 |
| **Version** | 1.0 |
| **Classification** | CUI (Controlled Unclassified Information) |
| **Framework** | NIST SP 800-61 Rev. 2, NIST SP 800-53 |
| **Applicable Systems** | All 13 Modernized Legacy Systems |
| **Review Cycle** | Semi-annual or after security incident |

## Purpose

This playbook provides detailed procedures for responding to cybersecurity incidents affecting the modernized legacy systems portfolio. It covers unauthorized access, vulnerability exploitation, malware, insider threats, and other security events.

---

## Phase 1: Preparation

### 1.1 Security-Specific Tools

| Tool | Purpose | Location |
|------|---------|----------|
| SIEM (Splunk/Sentinel) | Security event correlation | GovCloud instance |
| EDR (CrowdStrike/Carbon Black) | Endpoint threat detection | All server hosts |
| Network IDS (Suricata/Zeek) | Network threat detection | Network perimeter |
| Vulnerability Scanner (Nessus/Qualys) | Vulnerability assessment | Scan management server |
| Forensic Toolkit | Disk/memory forensics | Forensic workstation |
| YARA Rules | Malware indicator matching | IDS/EDR integration |
| Threat Intel Feed | IOC feeds | SIEM integration |

### 1.2 Security Monitoring Baseline

| System | Key Security Events to Monitor |
|--------|-------------------------------|
| Apache OFBiz | Failed logins (>5/min), SQL injection patterns, unauthorized API calls |
| Alfresco | Bulk document downloads, privilege escalation, unauthorized share access |
| Nuxeo | Mass content deletion, API key abuse, unauthorized bulk exports |
| B2CWeb | XSS/CSRF attempts, session hijacking, parameter tampering |
| Monolith Enterprise | EJB unauthorized invocation, JNDI injection, deserialization attacks |
| Odoo | XML-RPC abuse, module installation by non-admin, mass data export |
| Django Oscar | Payment data access anomalies, order manipulation, admin brute force |
| Mezzanine | Admin login brute force, file upload exploitation, template injection |
| Umbraco CMS | Back office unauthorized access, macro injection, file traversal |
| DFe-NET | Certificate theft/misuse, unauthorized fiscal document signing, SEFAZ impersonation |
| CFWheels | CFML injection, file inclusion, admin console access |
| NASTRAN-95 | Unauthorized model access, output data exfiltration |
| Apollo-11 | Source code tampering, unauthorized modification of preserved artifacts |

### 1.3 Access Control Verification

Before an incident occurs, maintain:

- [ ] Privileged access inventory for all 13 systems
- [ ] Service account inventory with rotation schedule
- [ ] API key/token inventory
- [ ] Certificate inventory with expiration tracking
- [ ] Network access control lists documented
- [ ] Multi-factor authentication enabled for all admin access

---

## Phase 2: Detection and Analysis

### 2.1 Security Event Categories

| Category | Description | Example Indicators |
|----------|-------------|-------------------|
| **Unauthorized Access** | Successful access without authorization | Unexpected logins, privilege escalation |
| **Exploitation** | Vulnerability being actively exploited | CVE-specific signatures, unusual process behavior |
| **Malware** | Malicious code execution | Unexpected processes, outbound C2 traffic |
| **Insider Threat** | Authorized user acting maliciously | Data exfiltration, policy violations |
| **Denial of Service** | Availability attack | Traffic spikes, resource exhaustion |
| **Supply Chain** | Compromised dependency | Unexpected library changes, backdoor code |

### 2.2 Indicator of Compromise (IOC) Collection

```bash
#!/bin/bash
# ioc-collection.sh - Collect IOCs from affected system
# Usage: ./ioc-collection.sh <system-name> <host>

SYSTEM=$1
HOST=$2
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
IOC_DIR="/evidence/ioc-${SYSTEM}-${TIMESTAMP}"
mkdir -p "$IOC_DIR"

echo "Collecting IOCs from $SYSTEM on $HOST..."

# Network connections
ssh $HOST "ss -tulnp" > "$IOC_DIR/network_connections.txt"
ssh $HOST "netstat -an" > "$IOC_DIR/netstat.txt"

# Running processes
ssh $HOST "ps auxef" > "$IOC_DIR/processes.txt"
ssh $HOST "lsof -i" > "$IOC_DIR/open_files_network.txt"

# Recent file modifications (last 24 hours)
ssh $HOST "find /opt /var /tmp -mtime -1 -type f -ls" > "$IOC_DIR/recent_files.txt"

# Login history
ssh $HOST "last -50" > "$IOC_DIR/login_history.txt"
ssh $HOST "lastb -50 2>/dev/null" > "$IOC_DIR/failed_logins.txt"

# Cron jobs
ssh $HOST "for u in \$(cut -f1 -d: /etc/passwd); do crontab -l -u \$u 2>/dev/null; done" > "$IOC_DIR/cron_jobs.txt"

# Systemd services (unexpected)
ssh $HOST "systemctl list-units --type=service --state=running" > "$IOC_DIR/running_services.txt"

# DNS cache / hosts file
ssh $HOST "cat /etc/hosts" > "$IOC_DIR/hosts_file.txt"
ssh $HOST "cat /etc/resolv.conf" > "$IOC_DIR/dns_config.txt"

# SSH authorized keys
ssh $HOST "find /home /root -name authorized_keys -exec echo {} \; -exec cat {} \;" > "$IOC_DIR/ssh_keys.txt"

echo "IOC collection complete: $IOC_DIR"
sha256sum "$IOC_DIR"/* > "$IOC_DIR/checksums.sha256"
```

### 2.3 Security Event Analysis Decision Tree

```
Security Event Detected
│
├─ Is it an active attack in progress?
│  ├─ YES → SEV-1 → Immediate containment (Phase 3.1)
│  └─ NO → Continue analysis
│
├─ Has data been accessed/exfiltrated?
│  ├─ YES → Is PII/sensitive data involved?
│  │  ├─ YES → SEV-1 → Data breach playbook (ir-playbook-data-breach.md)
│  │  └─ NO → SEV-2 → Continue incident handling
│  └─ NO/UNKNOWN → Continue analysis
│
├─ Is malware/ransomware involved?
│  ├─ YES → Ransomware playbook (ir-playbook-ransomware.md)
│  └─ NO → Continue
│
├─ Is it a known vulnerability exploitation?
│  ├─ YES → Check CVE impact across all 13 systems
│  └─ NO → Continue threat hunting
│
└─ Classify and handle per general IR playbook
```

### 2.4 Forensic Evidence Preservation

**Critical**: Follow chain of custody procedures for all evidence.

```bash
#!/bin/bash
# forensic-capture.sh - Capture forensic image
# Must run BEFORE containment actions

HOST=$1
EVIDENCE_DIR="/evidence/forensic-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EVIDENCE_DIR"

# Memory capture (prioritize - volatile)
ssh $HOST "sudo /opt/tools/avml /tmp/memory.lime"
scp $HOST:/tmp/memory.lime "$EVIDENCE_DIR/"
sha256sum "$EVIDENCE_DIR/memory.lime" >> "$EVIDENCE_DIR/chain_of_custody.txt"

# Disk image (if warranted)
# ssh $HOST "sudo dd if=/dev/sda bs=64K conv=noerror,sync | gzip" > "$EVIDENCE_DIR/disk.img.gz"

# Log preservation
for log_dir in /var/log /opt/*/logs /opt/*/runtime/logs; do
    ssh $HOST "tar czf /tmp/logs_$(basename $log_dir).tar.gz $log_dir 2>/dev/null"
    scp $HOST:/tmp/logs_*.tar.gz "$EVIDENCE_DIR/" 2>/dev/null
done

# Sign evidence
echo "Evidence captured by: $(whoami)" >> "$EVIDENCE_DIR/chain_of_custody.txt"
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$EVIDENCE_DIR/chain_of_custody.txt"
sha256sum "$EVIDENCE_DIR"/* >> "$EVIDENCE_DIR/chain_of_custody.txt"
```

---

## Phase 3: Containment, Eradication, and Recovery

### 3.1 Immediate Containment Actions

#### Network Isolation

```bash
# Isolate host at firewall level
sudo iptables -I INPUT -s <COMPROMISED_HOST_IP> -j DROP
sudo iptables -I OUTPUT -d <COMPROMISED_HOST_IP> -j DROP

# Or via network security group / firewall API
aws ec2 modify-instance-attribute \
  --instance-id <INSTANCE_ID> \
  --groups <ISOLATION_SECURITY_GROUP>
```

#### Service-Level Containment

| System Type | Containment Action |
|-------------|-------------------|
| Java (OFBiz, Alfresco, Nuxeo, B2CWeb, Monolith) | Stop application server; preserve heap dump |
| Python (Odoo, Oscar, Mezzanine) | Stop Gunicorn/WSGI; preserve process info |
| C# (Umbraco, DFe-NET) | Stop Kestrel/dotnet process; preserve dumps |
| ColdFusion (CFWheels) | Stop Lucee/CF engine; preserve servlet state |
| Fortran (NASTRAN-95) | Cancel running jobs; preserve scratch data |
| Assembly (Apollo-11) | Stop simulators; verify source integrity |

### 3.2 Credential Rotation

When credential compromise is suspected:

```bash
#!/bin/bash
# credential-rotation.sh - Rotate all credentials for a system

SYSTEM=$1

echo "=== Credential Rotation for $SYSTEM ==="

# Database passwords
echo "1. Rotate database passwords"
# Generate new password
NEW_DB_PASS=$(openssl rand -base64 32)
echo "   New DB password generated (stored in Vault)"

# Application secrets
echo "2. Rotate application secrets/API keys"
# System-specific steps here

# Service accounts
echo "3. Rotate service account passwords"

# SSL/TLS certificates (if compromised)
echo "4. Check if certificate rotation needed"

# Session invalidation
echo "5. Invalidate all active sessions"

echo "=== Rotation complete. Update configs and restart. ==="
```

### 3.3 Eradication by Attack Type

#### Web Application Attacks (OFBiz, Alfresco, B2CWeb, Oscar, Mezzanine, Umbraco, CFWheels)

```
1. Identify exploited vulnerability (CVE or custom)
2. Apply patch or WAF rule to block attack vector
3. Scan for web shells in upload directories
4. Review database for injected content
5. Check for unauthorized admin accounts
6. Verify file integrity against known-good baseline
```

#### Infrastructure Attacks (All Systems)

```
1. Patch exploited OS/middleware vulnerability
2. Remove unauthorized SSH keys / access
3. Check for rootkits (rkhunter, chkrootkit)
4. Verify systemd service integrity
5. Check for unauthorized cron jobs
6. Review and restore firewall rules
```

#### Supply Chain Attacks

```
1. Identify compromised dependency/library
2. Pin to known-good version
3. Rebuild from verified sources
4. Scan all 13 systems for same dependency
5. Update dependency management policy
```

### 3.4 Recovery with Enhanced Security

```
1. Rebuild/restore from known-good state
   └─> Follow system-specific runbook
   └─> Apply all security patches before reconnection

2. Enhanced monitoring (minimum 30 days)
   └─> Increase log verbosity
   └─> Add specific detection rules for attack pattern
   └─> Enable file integrity monitoring (AIDE/OSSEC)
   └─> Monitor for IOC recurrence

3. Gradual reconnection
   └─> Internal access first
   └─> Limited external access
   └─> Full production traffic
   └─> Verify no recurrence at each stage
```

---

## Phase 4: Post-Incident Activity

### 4.1 Security-Specific PIR Items

In addition to the general PIR (ir-playbook-general.md):

- Was the attack detectable with existing tools?
- Were detection rules adequate?
- Was the attack related to known vulnerabilities?
- Were patches available but not applied?
- Did the incident reveal gaps in security controls?
- Are other systems in the portfolio vulnerable to the same attack?

### 4.2 Security Control Updates

After each security incident, evaluate:

| Control Area | Review Items |
|-------------|-------------|
| Access Control | Account policies, MFA enforcement, privilege review |
| Vulnerability Management | Patch cadence, scan frequency, remediation SLA |
| Network Security | Firewall rules, segmentation, IDS signatures |
| Application Security | WAF rules, input validation, authentication |
| Monitoring | Detection rules, alert thresholds, coverage gaps |
| Incident Response | Playbook updates, tool improvements, training needs |

### 4.3 Federal Security Reporting

| Report | Recipient | Timeline | Trigger |
|--------|-----------|----------|---------|
| Initial Security Incident Report | CISA (US-CERT) | 1 hour | Confirmed cyber incident |
| Incident Update | CISA | Every 72 hours | Ongoing incident |
| Final Incident Report | CISA + Agency | 90 days | Incident closed |
| POA&M Update | AO (Authorizing Official) | 30 days | New vulnerability found |
| System Security Plan Update | ISSO | 60 days | Control changes |

### 4.4 Threat Intelligence Sharing

- Share IOCs with US-CERT / CISA via STIX/TAXII
- Update internal threat intel feed
- Notify peer agencies if shared infrastructure affected
- Contribute to sector-specific ISACs
