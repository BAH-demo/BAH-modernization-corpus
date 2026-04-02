# General Incident Response Playbook

## Document Control

| Field | Value |
|-------|-------|
| **Document ID** | IR-PLAY-001 |
| **Version** | 1.0 |
| **Classification** | CUI (Controlled Unclassified Information) |
| **Framework** | NIST SP 800-61 Rev. 2 |
| **Applicable Systems** | All 13 Modernized Legacy Systems |
| **Review Cycle** | Annual or after major incident |

## Purpose

This playbook establishes the general incident response procedures for all modernized legacy systems in the federal modernization portfolio. It follows the NIST SP 800-61 Rev. 2 (Computer Security Incident Handling Guide) four-phase approach and aligns with federal requirements including FISMA, FedRAMP, and agency-specific policies.

## Scope

This playbook covers all 13 systems in the modernization portfolio:

| Category | Systems |
|----------|---------|
| **Java** | Apache OFBiz, Alfresco Community, Nuxeo, B2CWeb, Monolith Enterprise |
| **Python** | Odoo, Django Oscar, Mezzanine |
| **C#** | Umbraco CMS, DFe-NET |
| **ColdFusion** | CFWheels |
| **Fortran** | NASTRAN-95 |
| **Assembly** | Apollo-11 |

---

## Phase 1: Preparation

### 1.1 Incident Response Team (IRT) Structure

| Role | Responsibility | Contact Method |
|------|---------------|----------------|
| **IR Manager** | Overall incident coordination, communication to leadership | Phone + Secure Email |
| **Triage Lead** | Initial assessment, severity classification | PagerDuty + Phone |
| **System Engineer** | Technical investigation and remediation | Slack + Phone |
| **Security Analyst** | Threat analysis, forensic investigation | Secure Channel |
| **Communications Lead** | Stakeholder notifications, status updates | Email + StatusPage |
| **Legal/Compliance** | Regulatory reporting, evidence preservation | Secure Email |
| **ISSO** | Information System Security Officer oversight | Phone + Email |

### 1.2 Communication Channels

| Channel | Purpose | Tool |
|---------|---------|------|
| Primary | Real-time coordination | Secure Slack / MS Teams (FedRAMP) |
| Secondary | Escalation and leadership | Phone bridge |
| Status Updates | Stakeholder communication | StatusPage / Email distribution |
| Evidence | Forensic data sharing | Encrypted file share (FIPS 140-2) |
| Documentation | Incident timeline and notes | Confluence / SharePoint (GovCloud) |

### 1.3 Preparation Checklist

- [ ] IR team contact list current and tested (quarterly)
- [ ] Communication channels tested and operational
- [ ] Incident response tools deployed and validated
- [ ] Jump bags (forensic kits) prepared for each system environment
- [ ] Backup and recovery procedures tested (per-system runbooks)
- [ ] SIEM/log aggregation operational for all 13 systems
- [ ] Alerting rules configured in Prometheus/AlertManager
- [ ] Tabletop exercises conducted (minimum annual)
- [ ] MOUs/MOAs with external parties current (US-CERT, law enforcement)
- [ ] Federal reporting contacts verified (CISA, agency SOC)

### 1.4 Severity Classification

| Severity | Definition | Response Time | Notification |
|----------|-----------|---------------|-------------|
| **SEV-1 (Critical)** | Complete system outage, data breach, active attack | 15 min | IRT + Leadership + CISA |
| **SEV-2 (High)** | Major functionality impaired, potential data exposure | 30 min | IRT + Management |
| **SEV-3 (Medium)** | Limited impact, single system degraded | 2 hours | IRT Lead + System Owner |
| **SEV-4 (Low)** | Minor issue, no user impact | Next business day | System Owner |

### 1.5 System Criticality Matrix

| System | Business Criticality | Data Sensitivity | Recovery Priority |
|--------|---------------------|-------------------|-------------------|
| Apache OFBiz | High | High (PII, Financial) | P1 |
| Odoo | High | High (PII, Financial) | P1 |
| DFe-NET | High | High (Fiscal/Regulatory) | P1 |
| Alfresco Community | High | Medium-High (Documents) | P2 |
| Nuxeo | High | Medium-High (Documents) | P2 |
| Django Oscar | High | High (PII, Payment) | P1 |
| Monolith Enterprise | Medium-High | Medium | P2 |
| Umbraco CMS | Medium | Low-Medium | P3 |
| B2CWeb | Medium | Medium (User Data) | P3 |
| Mezzanine | Medium | Low | P3 |
| CFWheels | Medium | Low-Medium | P3 |
| NASTRAN-95 | Medium | Low (Research) | P4 |
| Apollo-11 | Low | Low (Public/Historic) | P4 |

---

## Phase 2: Detection and Analysis

### 2.1 Detection Sources

| Source | Systems Covered | Alert Type |
|--------|----------------|------------|
| Prometheus/AlertManager | All 13 systems | Performance, availability |
| ELK Stack / Fluentd | All 13 systems | Log anomalies |
| SIEM (Splunk/Sentinel) | All 13 systems | Security events |
| Network IDS/IPS | All networked systems | Network threats |
| Endpoint Detection (EDR) | All server hosts | Host-based threats |
| User Reports | All user-facing systems | Functional issues |
| Vulnerability Scans | All 13 systems | Known CVEs |
| External Notification | All | US-CERT, vendor advisories |

### 2.2 Initial Triage Procedure

```
1. RECEIVE alert/report
   └─> Log in incident tracking system (ServiceNow/Jira)
   └─> Assign incident ID: INC-YYYY-NNNN

2. VERIFY the event
   └─> Confirm alert is not false positive
   └─> Check system-specific health endpoints (see runbooks)
   └─> Review recent deployment/change activity

3. CLASSIFY severity (see 1.4)
   └─> Assess scope: which systems affected?
   └─> Assess impact: users affected? data at risk?
   └─> Assess urgency: active attack? spreading?

4. ACTIVATE appropriate response
   └─> SEV-1/2: Activate full IRT, open war room
   └─> SEV-3: Assign to on-call engineer
   └─> SEV-4: Queue for next business day
```

### 2.3 Analysis Checklist

- [ ] Identify affected system(s) from the 13-system portfolio
- [ ] Review system-specific logs (see individual runbooks for log locations)
- [ ] Check SIEM for correlated events across systems
- [ ] Review recent changes (deployments, configuration, patches)
- [ ] Identify indicators of compromise (IOCs) if security-related
- [ ] Determine attack vector or root cause hypothesis
- [ ] Document timeline of events
- [ ] Assess blast radius (other systems potentially affected)
- [ ] Preserve volatile evidence (memory dumps, network captures)

### 2.4 System-Specific Log Locations Quick Reference

| System | Primary Log Path |
|--------|-----------------|
| Apache OFBiz | `/opt/ofbiz/runtime/logs/ofbiz.log` |
| Alfresco | `/opt/alfresco/tomcat/logs/alfresco.log` |
| Nuxeo | `/var/log/nuxeo/server.log` |
| B2CWeb | `/opt/tomcat/logs/b2cweb.log` |
| Monolith Enterprise | `/opt/wildfly/standalone/log/server.log` |
| Odoo | `/var/log/odoo/odoo-server.log` |
| Django Oscar | `/var/log/oscar/oscar.log` |
| Mezzanine | `/var/log/mezzanine/mezzanine.log` |
| Umbraco CMS | `/opt/umbraco/umbraco/Logs/UmbracoTraceLog.*.json` |
| DFe-NET | `/var/log/dfe-net/app.log` |
| CFWheels | `/opt/lucee/web/logs/exception.log` |
| NASTRAN-95 | `/data/nastran/results/*.f06` |
| Apollo-11 | `/opt/virtualagc/yaAGC.log` |

---

## Phase 3: Containment, Eradication, and Recovery

### 3.1 Containment Strategies

#### Short-Term Containment

| Action | When to Use | Impact |
|--------|-------------|--------|
| Isolate host from network | Active attack, lateral movement | System offline |
| Block malicious IPs/domains | Known threat indicators | Minimal if targeted |
| Disable compromised accounts | Credential compromise | User access disrupted |
| Enable WAF rules | Web application attack | Possible false positives |
| Redirect traffic (DNS/LB) | Single instance compromised | Failover to healthy instance |
| Shut down affected service | Active data exfiltration | System offline |

#### Long-Term Containment

| Action | When to Use |
|--------|-------------|
| Patch vulnerability | Known CVE exploitation |
| Rotate all credentials | Credential compromise |
| Rebuild system from clean image | Rootkit/persistent threat |
| Update firewall rules | Network-based attack |
| Enable enhanced monitoring | Ongoing threat activity |

### 3.2 Eradication Procedures

```
1. IDENTIFY root cause
   └─> Vulnerability exploited
   └─> Misconfiguration
   └─> Insider threat
   └─> Supply chain compromise

2. REMOVE threat
   └─> Delete malicious files/processes
   └─> Remove unauthorized accounts
   └─> Patch exploited vulnerabilities
   └─> Update configurations

3. VERIFY clean state
   └─> Run integrity checks (file hashes, configs)
   └─> Scan with updated signatures
   └─> Review all access logs post-remediation
   └─> Confirm no persistence mechanisms remain
```

### 3.3 Recovery Procedures

```
1. RESTORE from known-good state
   └─> Follow system-specific runbook for restore procedure
   └─> Use verified backups (pre-incident)
   └─> Apply all patches before reconnecting

2. VALIDATE system functionality
   └─> Run health checks per system runbook
   └─> Verify data integrity
   └─> Test critical business functions
   └─> Confirm monitoring is operational

3. RECONNECT to production
   └─> Gradual traffic restoration
   └─> Enhanced monitoring period (72 hours minimum)
   └─> Confirm no recurrence of incident
```

### 3.4 System-Specific Recovery Quick Reference

| System | Recovery Procedure | Estimated RTO |
|--------|-------------------|---------------|
| Apache OFBiz | DB restore + app redeploy | 2-4 hours |
| Alfresco | DB + content store restore | 2-4 hours |
| Nuxeo | DB + binary store restore | 2-4 hours |
| Odoo | DB + filestore restore | 1-2 hours |
| Django Oscar | DB + media restore | 1-2 hours |
| DFe-NET | DB restore + cert check | 1-2 hours |
| Umbraco CMS | DB restore + NuCache rebuild | 1-2 hours |
| B2CWeb | DB + WAR redeploy | 30-60 min |
| Mezzanine | DB + media restore | 30-60 min |
| Monolith Enterprise | DB + EAR redeploy | 1-2 hours |
| CFWheels | DB + app restore | 30-60 min |
| NASTRAN-95 | Reinstall from backup | 1-2 hours |
| Apollo-11 | Git restore + rebuild | 30 min |

---

## Phase 4: Post-Incident Activity

### 4.1 Post-Incident Review (PIR)

Conduct within **5 business days** of incident resolution:

#### PIR Agenda

1. **Timeline Review**: Walk through incident timeline from detection to resolution
2. **What Went Well**: Identify effective responses and tools
3. **What Needs Improvement**: Identify gaps, delays, or failures
4. **Root Cause Analysis**: Determine underlying cause (use 5 Whys method)
5. **Action Items**: Assign corrective actions with owners and deadlines
6. **Metrics Review**: MTTD, MTTR, impact scope

#### PIR Attendees

- IR Manager
- All IRT members who participated
- Affected system owners
- ISSO
- Management representative

### 4.2 Documentation Requirements

| Document | Contents | Retention |
|----------|----------|-----------|
| Incident Report | Full timeline, impact, actions, root cause | 3 years minimum |
| Evidence Log | Chain of custody, forensic artifacts | 7 years (federal) |
| Communication Log | All notifications sent | 3 years |
| Remediation Plan | Corrective actions, status tracking | Until completion |
| Lessons Learned | PIR findings and recommendations | Permanent |

### 4.3 Federal Reporting Requirements

| Reporting Body | Timeframe | Trigger |
|----------------|-----------|---------|
| US-CERT (CISA) | 1 hour (major), 72 hours (other) | All cybersecurity incidents |
| Agency SOC | Immediate | All incidents |
| Privacy Office | 72 hours | PII breach |
| Inspector General | As required | Fraud, waste, abuse indicators |
| Congress (via agency) | As required | Major incidents per FISMA |

### 4.4 Metrics to Track

| Metric | Definition | Target |
|--------|-----------|--------|
| MTTD | Mean Time to Detect | < 15 min (SEV-1), < 1 hour (SEV-2) |
| MTTR | Mean Time to Resolve | < 4 hours (SEV-1), < 8 hours (SEV-2) |
| MTTA | Mean Time to Acknowledge | < 5 min (SEV-1), < 15 min (SEV-2) |
| Incident Count | By severity per month | Trending downward |
| False Positive Rate | Alerts that are not incidents | < 20% |
| Recurrence Rate | Same root cause incidents | 0% |

### 4.5 Continuous Improvement

- Update this playbook after every SEV-1/SEV-2 incident
- Conduct tabletop exercises quarterly
- Review and test detection rules monthly
- Update system runbooks based on incident findings
- Train new team members on IR procedures
- Participate in agency-wide IR exercises annually
