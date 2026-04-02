# Ransomware Response Playbook

## Document Control

| Field | Value |
|-------|-------|
| **Document ID** | IR-PLAY-005 |
| **Version** | 1.0 |
| **Classification** | CUI (Controlled Unclassified Information) |
| **Framework** | NIST SP 800-61, CISA Ransomware Guide |
| **Applicable Systems** | All 13 Modernized Legacy Systems |
| **Review Cycle** | Semi-annual or after ransomware incident |

## Purpose

This playbook provides procedures for responding to ransomware attacks targeting the modernized legacy systems portfolio. It emphasizes rapid containment, secure recovery from backups, and avoiding ransom payment in accordance with federal policy.

**CRITICAL RULE**: Federal agencies should NOT pay ransoms. Recovery must be achieved through backups and system rebuilds.

---

## Phase 1: Preparation

### 1.1 Ransomware Prevention Controls

| Control | Implementation | Systems |
|---------|---------------|---------|
| Endpoint Protection (EDR) | CrowdStrike/Carbon Black on all hosts | All 13 |
| Email Filtering | Advanced threat protection | User-facing systems |
| Network Segmentation | Systems isolated by tier/function | All 13 |
| Backup Strategy | Offline/air-gapped + cloud backups | All 13 |
| Patch Management | 30-day critical, 90-day routine | All 13 |
| Application Whitelisting | AppLocker/SELinux policies | Production hosts |
| Privilege Management | Least privilege, no shared admin | All 13 |
| SMB/RDP Hardening | Disabled unnecessary, MFA on RDP | Windows hosts |

### 1.2 Backup Readiness (Critical for Ransomware Recovery)

| System | Backup Type | Frequency | Offline Copy | Last Test |
|--------|------------|-----------|--------------|-----------|
| Apache OFBiz | DB + Runtime | Daily | Weekly | [Date] |
| Alfresco | DB + Content Store | Daily | Weekly | [Date] |
| Nuxeo | DB + Binary Store | Daily | Weekly | [Date] |
| B2CWeb | DB + WAR | Daily | Weekly | [Date] |
| Monolith Enterprise | DB + EAR | Daily | Weekly | [Date] |
| Odoo | DB + Filestore | Daily | Weekly | [Date] |
| Django Oscar | DB + Media | Daily | Weekly | [Date] |
| Mezzanine | DB + Media | Daily | Weekly | [Date] |
| Umbraco CMS | DB + Media | Daily | Weekly | [Date] |
| DFe-NET | DB + Certs + XML | Daily | Weekly | [Date] |
| CFWheels | DB + App | Daily | Weekly | [Date] |
| NASTRAN-95 | Install + Models | Weekly | Monthly | [Date] |
| Apollo-11 | Source + Tools | On change | Monthly | [Date] |

### 1.3 Air-Gapped Backup Procedures

```bash
#!/bin/bash
# airgapped-backup.sh - Create offline backup copies
# Run on isolated backup server, not on production

BACKUP_SOURCE="/backup"
AIRGAP_MOUNT="/mnt/airgap-drive"  # External drive, disconnected after backup

# Mount air-gapped drive
mount /dev/sdb1 $AIRGAP_MOUNT

# Copy latest backups
for system in ofbiz alfresco nuxeo b2cweb monolith odoo oscar mezzanine umbraco dfe-net cfwheels nastran95 apollo11; do
    LATEST=$(ls -t $BACKUP_SOURCE/$system/ | head -1)
    if [ -n "$LATEST" ]; then
        rsync -av "$BACKUP_SOURCE/$system/$LATEST" "$AIRGAP_MOUNT/$system/"
        echo "Copied $system backup: $LATEST"
    fi
done

# Verify
sha256sum $AIRGAP_MOUNT/*/* > $AIRGAP_MOUNT/verification.sha256

# Unmount (CRITICAL - drive must be disconnected)
sync
umount $AIRGAP_MOUNT
echo "Air-gapped backup complete. DISCONNECT THE DRIVE NOW."
```

---

## Phase 2: Detection and Analysis

### 2.1 Ransomware Indicators

| Indicator | Detection Method | Urgency |
|-----------|-----------------|---------|
| Mass file encryption (.encrypted, .locked extensions) | File integrity monitoring | CRITICAL |
| Ransom note files (README.txt, DECRYPT_FILES.html) | File monitoring | CRITICAL |
| Unusual CPU/disk activity (encryption in progress) | Performance monitoring | HIGH |
| Shadow copy deletion (vssadmin, wmic) | Endpoint detection | CRITICAL |
| Lateral movement (PsExec, WMI, SMB) | Network IDS | HIGH |
| C2 communication to known ransomware infrastructure | Threat intel + DNS monitoring | HIGH |
| Disabled security tools (EDR, AV) | EDR health monitoring | CRITICAL |
| Bulk database encryption queries | Database audit logs | CRITICAL |

### 2.2 Immediate Verification Steps

```
UPON SUSPECTED RANSOMWARE:

1. DO NOT POWER OFF affected systems (preserves memory evidence)
2. DO NOT attempt to decrypt (may worsen encryption)
3. DO NOT communicate with attackers
4. DO immediately:

   a. ISOLATE the affected host(s) from the network
      └─> Pull network cable or disable NIC
      └─> Do NOT use WiFi disconnect (may trigger killswitch)

   b. PHOTOGRAPH any ransom notes on screen
   
   c. NOTE the exact time of detection
   
   d. ASSESS spread:
      └─> Which systems show encryption?
      └─> Is encryption still in progress?
      └─> Are other systems reachable from affected hosts?
```

### 2.3 Scope Assessment

```bash
#!/bin/bash
# ransomware-scope-check.sh
# Check all 13 systems for ransomware indicators

echo "=== Ransomware Scope Assessment ==="
echo "Timestamp: $(date -u)"

# Check each system host
declare -A HOSTS=(
    ["ofbiz"]="ofbiz-prod-01"
    ["alfresco"]="alfresco-prod-01"
    ["nuxeo"]="nuxeo-prod-01"
    ["b2cweb"]="b2cweb-prod-01"
    ["monolith"]="monolith-prod-01"
    ["odoo"]="odoo-prod-01"
    ["oscar"]="oscar-prod-01"
    ["mezzanine"]="mezzanine-prod-01"
    ["umbraco"]="umbraco-prod-01"
    ["dfe-net"]="dfe-net-prod-01"
    ["cfwheels"]="cfwheels-prod-01"
    ["nastran95"]="nastran-prod-01"
    ["apollo11"]="apollo-prod-01"
)

for system in "${!HOSTS[@]}"; do
    HOST=${HOSTS[$system]}
    echo ""
    echo "--- Checking $system ($HOST) ---"
    
    # Check for ransom notes
    ssh $HOST "find / -maxdepth 3 -name 'README*.txt' -o -name 'DECRYPT*' -o -name '*RANSOM*' -o -name '*LOCKED*' 2>/dev/null" | head -10
    
    # Check for encrypted files
    ssh $HOST "find /opt /var /data -name '*.encrypted' -o -name '*.locked' -o -name '*.crypto' 2>/dev/null | head -5"
    
    # Check if key services are running
    ssh $HOST "systemctl is-active $system 2>/dev/null || echo 'SERVICE DOWN'"
    
    # Check for suspicious processes
    ssh $HOST "ps aux | grep -iE 'crypt|ransom|lock' | grep -v grep" 2>/dev/null
    
    # Check disk I/O (high = possible encryption in progress)
    ssh $HOST "iostat -x 1 1 | tail -5" 2>/dev/null
done

echo ""
echo "=== Scope assessment complete ==="
```

### 2.4 Ransomware Identification

```bash
# Collect samples for identification
# (Do this from isolated forensic workstation)

# 1. Collect encrypted file sample + original (if available)
scp affected-host:/path/to/encrypted-file /evidence/samples/
scp affected-host:/path/to/ransom-note /evidence/samples/

# 2. Use identification tools
# - ID Ransomware (https://id-ransomware.malwarehunterteam.com/)
# - No More Ransom (https://www.nomoreransom.org/)
# - Upload to malware sandbox (in isolated environment)

# 3. Document ransomware variant
echo "Ransomware Variant: [IDENTIFIED NAME]"
echo "Known Decryptor Available: [YES/NO]"
echo "Encryption Algorithm: [IF KNOWN]"
```

---

## Phase 3: Containment, Eradication, and Recovery

### 3.1 Containment Priority Order

```
IMMEDIATE (Minutes):
1. Network isolate ALL affected systems
2. Disable shared network drives/shares (NFS, SMB, CIFS)
3. Block ransomware C2 domains/IPs at firewall
4. Disable compromised accounts
5. Preserve evidence (DO NOT WIPE YET)

SHORT-TERM (Hours):
6. Isolate backup infrastructure (ensure backups are safe)
7. Verify air-gapped backups are intact
8. Network isolate UNAFFECTED systems preventively
9. Disable email/web access to prevent further spread
10. Document all containment actions with timestamps

ASSESSMENT (Hours):
11. Determine encryption scope across all 13 systems
12. Identify the ransomware variant
13. Check for available decryptors
14. Assess backup viability for each affected system
```

### 3.2 Network Containment

```bash
# Emergency network isolation script
# Run from network management console

# Block all inter-system traffic
for host in ofbiz alfresco nuxeo b2cweb monolith odoo oscar mezzanine umbraco dfe-net cfwheels nastran apollo; do
    iptables -I FORWARD -s ${host}_IP -j DROP
    iptables -I FORWARD -d ${host}_IP -j DROP
done

# Block known ransomware C2 (update with specific IOCs)
# iptables -I OUTPUT -d <C2_IP> -j DROP

# Allow only management access
# iptables -I INPUT -s <MANAGEMENT_SUBNET> -p tcp --dport 22 -j ACCEPT

echo "Network containment applied"
echo "WARNING: All inter-system communication is blocked"
```

### 3.3 Recovery Procedures

**IMPORTANT**: Recover systems in priority order based on business criticality.

#### Recovery Priority Order

| Priority | Systems | Justification |
|----------|---------|---------------|
| P1 | DFe-NET, Odoo, OFBiz | Fiscal compliance, ERP operations |
| P2 | Django Oscar, Alfresco, Nuxeo | Revenue, document access |
| P3 | Monolith Enterprise, B2CWeb, Umbraco | Business operations |
| P4 | Mezzanine, CFWheels | Content, lower criticality |
| P5 | NASTRAN-95, Apollo-11 | Research, preservation |

#### Per-System Recovery Process

```
FOR EACH AFFECTED SYSTEM:

1. VERIFY backup integrity
   └─> Check offline/air-gapped backup first
   └─> Verify checksums against pre-incident records
   └─> If cloud backup, verify it wasn't encrypted too

2. PROVISION clean infrastructure
   └─> New VM or rebuilt host (DO NOT reuse compromised host)
   └─> Fresh OS installation from verified media
   └─> Apply all security patches
   └─> Harden per security baseline

3. RESTORE application
   └─> Install application from verified source (not backup of compromised system)
   └─> Restore data from verified clean backup
   └─> Follow system-specific runbook restore procedures

4. VALIDATE before reconnecting
   └─> Run system health checks
   └─> Verify data integrity
   └─> Scan for ransomware indicators
   └─> Test with limited access first

5. RECONNECT with enhanced monitoring
   └─> Gradual traffic restoration
   └─> File integrity monitoring enabled
   └─> Enhanced logging
   └─> 72-hour heightened monitoring period
```

#### Database Recovery

```bash
#!/bin/bash
# ransomware-db-recovery.sh
# Recover databases from clean backups

SYSTEM=$1
BACKUP_PATH=$2  # Path to verified clean backup

echo "=== Database Recovery for $SYSTEM ==="

# Verify backup integrity
echo "1. Verifying backup integrity..."
case $SYSTEM in
    ofbiz|alfresco|nuxeo|odoo|oscar|mezzanine)
        pg_restore -l "$BACKUP_PATH" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "FATAL: Backup integrity check failed"
            exit 1
        fi
        echo "   PostgreSQL backup verified"
        
        # Restore
        echo "2. Restoring database..."
        createdb -U postgres "${SYSTEM}_recovered"
        pg_restore -U postgres -d "${SYSTEM}_recovered" --clean --if-exists "$BACKUP_PATH"
        ;;
        
    umbraco|dfe-net)
        echo "   SQL Server backup - using sqlcmd for restore"
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
          -Q "RESTORE VERIFYONLY FROM DISK = '$BACKUP_PATH'"
        if [ $? -ne 0 ]; then
            echo "FATAL: SQL Server backup verification failed"
            exit 1
        fi
        
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
          -Q "RESTORE DATABASE ${SYSTEM}_recovered FROM DISK = '$BACKUP_PATH' WITH REPLACE"
        ;;
        
    b2cweb|cfwheels)
        echo "   MySQL backup"
        mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${SYSTEM}_recovered;"
        mysql -u root "${SYSTEM}_recovered" < "$BACKUP_PATH"
        ;;
esac

echo "3. Database recovery complete for $SYSTEM"
echo "   IMPORTANT: Verify data integrity before production use"
```

### 3.4 Eradication

```
1. IDENTIFY the initial infection vector
   └─> Phishing email?
   └─> Exploited vulnerability?
   └─> Compromised credentials?
   └─> Supply chain?

2. CLOSE the infection vector
   └─> Patch vulnerability
   └─> Block malicious email/URL
   └─> Rotate all credentials
   └─> Update security controls

3. SCAN all systems
   └─> Full antivirus/EDR scan on all 13 system hosts
   └─> Check for dormant payloads
   └─> Verify no persistence mechanisms
   └─> Check scheduled tasks/cron for malicious entries

4. VERIFY clean state
   └─> File integrity checks against known-good baselines
   └─> Network traffic analysis (no C2 communication)
   └─> Memory forensics on previously affected hosts
```

---

## Phase 4: Post-Incident Activity

### 4.1 Federal Reporting Requirements

| Report | To | Timeline |
|--------|-------|----------|
| Ransomware Incident Report | CISA (StopRansomware.gov) | 24 hours |
| US-CERT Incident Report | CISA | 1 hour |
| FBI Report | IC3 (ic3.gov) | 72 hours |
| Agency CIO/CISO Briefing | Internal | Same day |
| Congressional Notification | If major impact | Per FISMA |
| OMB Notification | If major incident | Per OMB M-20-04 |

### 4.2 Post-Incident Recovery Metrics

| Metric | Measure |
|--------|---------|
| Time to Detection | First indicator → confirmed ransomware |
| Time to Containment | Detection → full network isolation |
| Time to Recovery (per system) | Containment → service restored |
| Data Loss (RPO achieved) | Last clean backup → incident time |
| Total Business Impact | Downtime × system criticality |
| Cost of Recovery | Infrastructure, labor, vendor costs |

### 4.3 Hardening Actions Post-Ransomware

| Action | Timeline | Priority |
|--------|----------|----------|
| Implement or enhance network segmentation | 30 days | Critical |
| Deploy/update EDR on all hosts | 7 days | Critical |
| Implement air-gapped backup testing (monthly) | 14 days | Critical |
| Enable MFA on all admin/remote access | 7 days | Critical |
| Review and restrict SMB/RDP access | 7 days | High |
| Implement application whitelisting | 60 days | High |
| Deploy file integrity monitoring (AIDE/OSSEC) | 30 days | High |
| Implement privileged access management (PAM) | 60 days | High |
| Conduct phishing awareness training | 30 days | Medium |
| Implement DNS filtering/sinkholing | 14 days | Medium |
| Review backup strategy and test restores | 7 days | Critical |

### 4.4 Lessons Learned Template

```
Ransomware Incident Post-Mortem Report
========================================

Incident ID: [INC-YYYY-NNNN]
Date of Incident: [Date]
Ransomware Variant: [Name/Family]
Systems Affected: [List of 13 systems affected]

1. Timeline
   - Initial compromise: [Date/Time]
   - Ransomware execution: [Date/Time]
   - Detection: [Date/Time]
   - Containment: [Date/Time]
   - Recovery start: [Date/Time]
   - Full recovery: [Date/Time]

2. Impact
   - Systems encrypted: [Count/Names]
   - Data loss: [Description]
   - Downtime: [Hours per system]
   - Financial impact: [Estimate]

3. Root Cause
   [Detailed root cause analysis]

4. What Worked
   [Effective response elements]

5. What Didn't Work
   [Gaps and failures]

6. Corrective Actions
   [Action items with owners and deadlines]

7. Backup Effectiveness
   - Were backups intact? [Yes/No per system]
   - RPO achieved: [Hours of data loss per system]
   - Restore time: [Hours per system]
```
