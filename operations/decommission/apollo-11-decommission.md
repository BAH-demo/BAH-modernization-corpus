# Apollo-11 Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Apollo-11 |
| **Type** | Historic Preservation / AGC Simulator |
| **Language** | Assembly (AGC) |
| **Criticality** | Tier 3 (Cultural/Historic) |
| **Target Decommission Date** | [TBD] |
| **Modernized Replacement** | [Replacement System Name] |

---

## 1. Pre-Decommission Checklist

### 1.1 Stakeholder Approval

- [ ] System Owner sign-off obtained
- [ ] Historic Preservation Officer approval
- [ ] ISSO security review completed
- [ ] Authorizing Official (AO) approval
- [ ] Change Advisory Board (CAB) approval
- [ ] NARA (National Archives) notification (if applicable)
- [ ] Smithsonian/NASA coordination (if applicable)

### 1.2 Replacement System Validation

- [ ] Modernized preservation platform fully operational
- [ ] All source code (Comanche055, Luminary099) preserved exactly
- [ ] AGC simulator functionality replicated or preserved
- [ ] DSKY emulator accessible on replacement platform
- [ ] Bit-for-bit integrity verification passed
- [ ] Research access maintained
- [ ] Educational/public access maintained
- [ ] UAT completed
- [ ] Parallel operation period completed (minimum 14 days)

### 1.3 Special Preservation Considerations

- [ ] Source code SHA-256 checksums recorded and verified
- [ ] Digital preservation metadata (Dublin Core) complete
- [ ] OAIS (Open Archival Information System) compliance verified
- [ ] Multiple redundant copies exist (LOCKSS principle)
- [ ] Public GitHub repository remains accessible (upstream)

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| AGC source code (Comanche055) | ~4K LOC | Permanent | Git + multiple archives |
| AGC source code (Luminary099) | ~4K LOC | Permanent | Git + multiple archives |
| yaAGC simulator source | ~50K LOC | Permanent | Git archive |
| Build artifacts | ~10 MB | Permanent | Binary archive |
| Documentation | ~100 MB | Permanent | File archive |
| Simulation logs | ~1 GB | 10 years | File archive |
| Verification test data | ~500 MB | Permanent | File archive |

### 2.2 Preservation Archival

```bash
#!/bin/bash
# apollo11-preserve.sh
# Multiple redundant archives per LOCKSS principle

ARCHIVE_DIR="/archive/apollo-11"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

# Complete system archive
tar czf "$ARCHIVE_DIR/apollo11_complete_${TIMESTAMP}.tar.gz" /opt/virtualagc/

# Source code with integrity verification
cp -r /opt/virtualagc/Comanche055/ "$ARCHIVE_DIR/Comanche055/"
cp -r /opt/virtualagc/Luminary099/ "$ARCHIVE_DIR/Luminary099/"

# Generate checksums for every source file
find "$ARCHIVE_DIR/Comanche055/" "$ARCHIVE_DIR/Luminary099/" -type f | while read f; do
    sha256sum "$f"
done > "$ARCHIVE_DIR/source_integrity_${TIMESTAMP}.sha256"

# Build tools archive
tar czf "$ARCHIVE_DIR/apollo11_tools_${TIMESTAMP}.tar.gz" \
    /opt/virtualagc/yaYUL/ \
    /opt/virtualagc/yaAGC/ \
    /opt/virtualagc/yaDSKY/

# Documentation archive
tar czf "$ARCHIVE_DIR/apollo11_docs_${TIMESTAMP}.tar.gz" /opt/virtualagc/docs/

# Master manifest
cd "$ARCHIVE_DIR"
sha256sum *.tar.gz *.sha256 > master_manifest_${TIMESTAMP}.sha256

echo "PRESERVATION NOTE: This archive contains historically significant"
echo "NASA Apollo Guidance Computer source code. Handle per NARA guidelines."
```

### 2.3 Preservation Standards

```
This system contains historically significant artifacts.
Decommission does NOT mean destruction.

Preservation requirements:
1. Minimum 3 geographically distributed copies
2. At least 1 copy on different storage media
3. Integrity verification every 6 months
4. Format migration as needed (per OAIS)
5. Permanent retention - no destruction date
6. Public access must be maintained
```

---

## 3. DNS/Routing Cutover

| Step | Action | Duration |
|------|--------|----------|
| 1 | Update documentation links to replacement platform | 1 hour |
| 2 | Configure redirect from old simulator URL | 15 min |
| 3 | Update educational/public access URLs | 30 min |
| 4 | Notify research community | 1 week advance notice |

---

## 4. Legacy System Shutdown Sequence

```
1. Final integrity verification
   └─> Run SHA-256 checks on all source files
   └─> Compare against published checksums

2. Stop AGC simulator services
   └─> systemctl stop yaagc-simulator
   └─> systemctl stop yadsky-emulator

3. Archive complete system state
   └─> Run preservation archival script

4. Verify archives are complete and accessible

5. Disable services
   └─> systemctl disable yaagc-simulator yadsky-emulator

6. Keep source code in read-only state for research reference
   └─> OR power down if replacement is fully operational

7. Update public documentation
```

---

## 5. Post-Decommission Validation

- [ ] Simulator no longer running on legacy infrastructure
- [ ] Replacement preservation platform accessible
- [ ] Source code integrity verified on replacement
- [ ] Public access to code maintained
- [ ] Research/educational use uninterrupted
- [ ] Archive integrity verified across all copies
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| AGC source code | Permanent | NARA / historic significance |
| Simulator tools | Permanent | Research preservation |
| Build artifacts | Permanent | Verification purposes |
| Documentation | Permanent | Historic/educational value |
| Simulation logs | 10 years | Research records |

### 6.1 Special Historic Preservation Requirements

- Apollo-11 AGC source code is a nationally significant digital artifact
- NARA guidelines for permanent digital preservation apply
- Smithsonian digital preservation standards recommended
- Library of Congress digital preservation best practices
- UNESCO Memory of the World Programme consideration

---

## 7. Rollback Procedures

```
1. Restore from Git repository (primary source)
   └─> git clone [upstream-repo-url]
2. Rebuild yaAGC tools from source
   └─> cd yaAGC && make
3. Start simulator services
   └─> systemctl start yaagc-simulator
4. Verify against known checksums
5. Restore public access
```

**Estimated rollback time**: 30-60 minutes (source is in public Git repos)

**NOTE**: Due to the public and open-source nature of this system, rollback risk is minimal. The upstream GitHub repository serves as a permanent, redundant backup.
