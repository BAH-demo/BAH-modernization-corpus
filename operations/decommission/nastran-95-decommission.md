# NASTRAN-95 Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | NASTRAN-95 |
| **Type** | Structural Analysis (FEA) |
| **Language** | Fortran |
| **Criticality** | Tier 3 |
| **Target Decommission Date** | [TBD] |
| **Modernized Replacement** | [Replacement System Name] |

---

## 1. Pre-Decommission Checklist

### 1.1 Stakeholder Approval

- [ ] System Owner sign-off obtained
- [ ] Engineering/Research department approval
- [ ] ISSO security review completed
- [ ] Authorizing Official (AO) approval
- [ ] Change Advisory Board (CAB) approval
- [ ] Export control officer approval (ITAR/EAR review)

### 1.2 Replacement System Validation

- [ ] Replacement FEA tool validated against NASTRAN-95 benchmark results
- [ ] All solution sequences (SOL 101, 103, etc.) available in replacement
- [ ] Model conversion tools tested and validated
- [ ] Existing BDF/NAS input files convertible to replacement format
- [ ] Results within acceptable tolerance (±0.1% for stress, ±0.01% for displacement)
- [ ] Batch job submission working on replacement
- [ ] UAT completed by engineering team
- [ ] Parallel operation period completed (minimum 60 days)

### 1.3 Special Considerations

- [ ] ITAR/export control review for data migration
- [ ] NASA/government IP rights verified
- [ ] Research data preservation per agency policy
- [ ] Active analysis jobs completed before shutdown
- [ ] Published research referencing NASTRAN-95 results documented

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Input models (BDF/NAS files) | ~50 GB | Permanent (research) | File archive |
| Analysis results (F06/OP2) | ~500 GB | 10 years minimum | File archive |
| Compiled executables | ~100 MB | 3 years | File archive |
| Source code (Fortran) | ~150K LOC | Permanent | Git archive |
| Validation/benchmark data | ~5 GB | Permanent | File archive |
| Job scripts (SLURM/PBS) | ~500 files | 3 years | File archive |
| Documentation/manuals | ~200 MB | Permanent | File archive |

### 2.2 Archival Procedure

```bash
#!/bin/bash
ARCHIVE_DIR="/archive/nastran95"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

# Source code archive
tar czf "$ARCHIVE_DIR/nastran95_source_${TIMESTAMP}.tar.gz" /opt/nastran95/source/

# Input models archive
tar czf "$ARCHIVE_DIR/nastran95_models_${TIMESTAMP}.tar.gz" /data/nastran/models/

# Results archive (may be very large)
tar czf "$ARCHIVE_DIR/nastran95_results_${TIMESTAMP}.tar.gz" /data/nastran/results/

# Benchmarks and validation
tar czf "$ARCHIVE_DIR/nastran95_benchmarks_${TIMESTAMP}.tar.gz" /data/nastran/benchmarks/

# Documentation
tar czf "$ARCHIVE_DIR/nastran95_docs_${TIMESTAMP}.tar.gz" /opt/nastran95/docs/

# Job scripts
tar czf "$ARCHIVE_DIR/nastran95_jobs_${TIMESTAMP}.tar.gz" /data/nastran/jobs/

# Checksums
cd "$ARCHIVE_DIR"
sha256sum *.tar.gz > manifest_${TIMESTAMP}.sha256
```

---

## 3. DNS/Routing Cutover

NASTRAN-95 is typically not web-accessible. Cutover involves:

| Step | Action | Duration |
|------|--------|----------|
| 1 | Update job scheduler configuration | 30 min |
| 2 | Remove NASTRAN-95 from compute cluster modules | 15 min |
| 3 | Update environment modules (module avail) | 15 min |
| 4 | Update user documentation/wiki | 1 hour |
| 5 | Send user notification email | 15 min |

---

## 4. Legacy System Shutdown Sequence

```
1. Cancel any queued SLURM/PBS jobs
   └─> scancel -u nastran_service
   └─> qdel $(qselect -u nastran_service)

2. Wait for running analyses to complete (or set deadline)

3. Remove NASTRAN-95 module
   └─> Remove from /etc/modulefiles/ or /opt/modules/
   └─> module avail | grep nastran  # verify removed

4. Remove compiled binaries
   └─> Archive first, then remove from /opt/nastran95/bin/

5. Clean scratch space
   └─> rm -rf /scratch/nastran/*

6. Remove from job scheduler
   └─> Remove NASTRAN-95 queue/partition definitions

7. Archive all data (per section 2)
8. Decommission dedicated compute nodes (if any)
9. Update HPC documentation
```

---

## 5. Post-Decommission Validation

- [ ] NASTRAN-95 not available via module system
- [ ] Job submissions to NASTRAN-95 queue rejected
- [ ] Replacement FEA tool accessible to all users
- [ ] Benchmark results verified on replacement
- [ ] Documentation updated with replacement tool instructions
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Source code (NASA origin) | Permanent | NASA data policy |
| Engineering analysis results | 10 years minimum | Agency records schedule |
| Benchmark data | Permanent | Research preservation |
| Input models | Per project lifecycle | Project records schedule |
| ITAR-controlled data | Per ITAR requirements | 22 CFR 120-130 |

### 6.1 Export Control Considerations

- All NASTRAN-95 data must be reviewed for export control markings
- ITAR-controlled data must remain within authorized systems
- Data transfers to replacement system must comply with export regulations
- International collaborator access must be re-evaluated

---

## 7. Rollback Procedures

```
1. Restore NASTRAN-95 module files
2. Restore compiled binaries from archive
3. Re-enable SLURM/PBS queue definitions
4. Verify compilation: nastran test_model.bdf
5. Run benchmark suite to validate
6. Notify users of availability
```

**Estimated rollback time**: 2-4 hours (primarily module/queue reconfiguration)
