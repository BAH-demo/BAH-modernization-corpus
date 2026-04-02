# NASTRAN-95 Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | NASTRAN-95 |
| **Type** | Structural Analysis / Finite Element Analysis |
| **Language** | Fortran |
| **Tier** | Tier 3 - Federal/Legacy System |
| **LOC** | 150,000+ |
| **Category** | Scientific Computing / Structural Engineering |
| **Criticality** | High (engineering calculations) |

### Architecture

NASTRAN-95 is a Fortran-based finite element analysis (FEA) program developed by NASA:

- **Executive System**: Job control and module sequencing (DMAP)
- **Functional Modules**: Structural analysis, dynamics, heat transfer
- **Matrix Operations**: BANDED, DECOMP, FBS matrix solvers
- **Data Management**: GINO (General Input/Output) database system
- **Input Processing**: Bulk Data Deck (BDD) parser

```
┌─────────────────────────────────────────┐
│          Job Submission System           │
│         (SLURM / PBS / Manual)          │
├─────────────────────────────────────────┤
│         NASTRAN-95 Executable           │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │Executive│ │Functional│ │  Matrix  │ │
│  │ System  │ │ Modules  │ │ Solvers  │ │
│  └─────────┘ └──────────┘ └──────────┘ │
├─────────────────────────────────────────┤
│    GINO Database    │  Scratch Files    │
│   (Input/Output)    │  (Temp Storage)   │
└─────────────────────┴───────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores | 16+ cores |
| RAM | 8 GB | 64 GB (model-dependent) |
| Disk | 50 GB SSD | 500 GB NVMe SSD |
| Fortran Compiler | gfortran 9+ | Intel Fortran 2021+ |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Fortran compiler (gfortran 9+ or Intel Fortran)
- BLAS/LAPACK libraries (OpenBLAS or Intel MKL)
- Make/CMake (build system)
- Python 3 (pre/post-processing scripts, optional)
- SLURM or PBS Pro (job scheduling, for HPC environments)

### Storage Requirements

| Directory | Purpose | Size |
|-----------|---------|------|
| `/opt/nastran95/` | Installation | 500 MB |
| `/data/nastran/models/` | Input models | Variable |
| `/data/nastran/results/` | Output results | Variable |
| `/scratch/nastran/` | Temporary/scratch | 10× model size |

## Startup and Shutdown Procedures

### Running an Analysis Job

```bash
# 1. Prepare input deck
cp model.bdf /data/nastran/models/

# 2. Run NASTRAN analysis
cd /data/nastran/models/
/opt/nastran95/bin/nastran model.bdf \
  scratch=/scratch/nastran/ \
  memory=8gb \
  out=/data/nastran/results/model

# 3. Check completion
grep "TOTAL.*TIME" /data/nastran/results/model.f06
```

### Batch Job Submission (SLURM)

```bash
#!/bin/bash
#SBATCH --job-name=nastran-analysis
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/data/nastran/results/%j.out

module load nastran95
module load openblas

cd $SLURM_SUBMIT_DIR
/opt/nastran95/bin/nastran $INPUT_FILE \
  scratch=$TMPDIR \
  memory=${SLURM_MEM_PER_NODE}mb
```

### Cancelling a Job

```bash
# SLURM
scancel $JOB_ID

# Manual process
kill -SIGTERM $(pgrep -f nastran)
# Clean scratch files
rm -rf /scratch/nastran/$JOB_ID/
```

## Health Check and Validation

### Build Verification

```bash
#!/bin/bash
# nastran-verify.sh - Run validation test suite

cd /opt/nastran95/test-cases/

# Run standard validation problems
for test in static_bar.bdf modal_plate.bdf thermal_block.bdf; do
    echo "Running $test..."
    /opt/nastran95/bin/nastran "$test" \
      scratch=/scratch/nastran/test/ \
      out=/tmp/nastran-verify/$(basename $test .bdf)

    # Check for FATAL errors
    if grep -q "FATAL" /tmp/nastran-verify/$(basename $test .bdf).f06; then
        echo "FAIL: $test - FATAL error found"
        exit 2
    fi

    # Verify results against reference
    python3 /opt/nastran95/tools/compare_results.py \
      /tmp/nastran-verify/$(basename $test .bdf).f06 \
      /opt/nastran95/test-cases/reference/$(basename $test .bdf).ref \
      --tolerance=0.01

    if [ $? -ne 0 ]; then
        echo "FAIL: $test - Results outside tolerance"
        exit 1
    fi
done

echo "OK: All validation tests passed"
exit 0
```

### System Health Check

```bash
#!/bin/bash
# Check compiler
gfortran --version > /dev/null 2>&1 || { echo "CRITICAL: Fortran compiler not found"; exit 2; }

# Check BLAS/LAPACK
ldconfig -p | grep -q "libblas\|libopenblas" || { echo "WARNING: BLAS library not found"; exit 1; }

# Check scratch space
SCRATCH_FREE=$(df -BG /scratch/nastran/ | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$SCRATCH_FREE" -lt 50 ]; then
    echo "WARNING: Scratch space low (${SCRATCH_FREE}GB free)"
    exit 1
fi

# Check memory
FREE_MEM=$(free -g | awk '/Mem:/ {print $7}')
if [ "$FREE_MEM" -lt 8 ]; then
    echo "WARNING: Low available memory (${FREE_MEM}GB)"
    exit 1
fi

echo "OK: NASTRAN-95 environment healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. FATAL Error in Analysis

**Symptoms**: `*** USER FATAL MESSAGE` in .f06 output

**Resolution**:
```bash
# Extract FATAL messages
grep -A5 "FATAL" /data/nastran/results/model.f06

# Common causes:
# - Singular stiffness matrix: Check boundary conditions
# - Insufficient memory: Increase memory parameter
# - Bad element connectivity: Check grid/element definitions

# Re-run with diagnostics
/opt/nastran95/bin/nastran model.bdf \
  scratch=/scratch/nastran/ \
  memory=16gb \
  diag=1,8,14
```

### 2. Out of Memory

**Symptoms**: `INSUFFICIENT CORE` or `MEMORY ALLOCATION FAILURE`

**Resolution**:
```bash
# Check model size requirements
grep "MEMORY" /data/nastran/results/model.f06

# Re-run with more memory
/opt/nastran95/bin/nastran model.bdf \
  scratch=/scratch/nastran/ \
  memory=32gb

# For very large models, use out-of-core solver
/opt/nastran95/bin/nastran model.bdf \
  scratch=/scratch/nastran/ \
  memory=16gb \
  buffsize=32769
```

### 3. Scratch Disk Full

**Symptoms**: `I/O ERROR` or analysis hangs

**Resolution**:
```bash
# Check scratch usage
du -sh /scratch/nastran/*

# Clean old scratch files
find /scratch/nastran/ -mtime +7 -delete

# Redirect scratch to larger volume
/opt/nastran95/bin/nastran model.bdf \
  scratch=/large-volume/nastran-scratch/
```

### 4. Numerical Convergence Failures

**Symptoms**: `EPSILON` warnings; non-converging nonlinear analysis

**Resolution**:
```bash
# Check convergence diagnostics
grep -i "epsilon\|convergence\|iteration" /data/nastran/results/model.f06 | tail -30

# Adjust convergence parameters in input deck:
# PARAM,EPSHT,-1  (heat transfer convergence)
# NLPARM,1,25,AUTO,,,,P  (nonlinear parameters)

# Try smaller load increments
# Modify SUBCASE load steps in input deck
```

## Log Locations and Log Analysis

| Output File | Extension | Purpose |
|-------------|-----------|---------|
| Print File | `.f06` | Main output with results, diagnostics, error messages |
| Punch File | `.pch` | Tabular results output |
| Plot File | `.plt` | Graphical output data |
| DMAP Log | `.log` | Module execution sequence |
| Op2 File | `.op2` | Binary results database |

### Log Analysis Commands

```bash
# Check for errors
grep -c "FATAL\|WARNING\|ERROR" /data/nastran/results/model.f06

# Extract timing information
grep "MODULE.*TIME" /data/nastran/results/model.f06

# Extract displacement summary
grep -A20 "D I S P L A C E M E N T" /data/nastran/results/model.f06 | head -25

# Check model statistics
grep "NUMBER OF.*ELEMENTS\|GRID POINTS\|DEGREES" /data/nastran/results/model.f06
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/nastran95/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Installation and configuration
tar czf "$BACKUP_DIR/nastran95_install.tar.gz" /opt/nastran95/

# Model library
tar czf "$BACKUP_DIR/nastran_models.tar.gz" /data/nastran/models/

# Results archive
tar czf "$BACKUP_DIR/nastran_results.tar.gz" /data/nastran/results/

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"
tar xzf "$BACKUP_DIR/nastran95_install.tar.gz" -C /
tar xzf "$BACKUP_DIR/nastran_models.tar.gz" -C /
tar xzf "$BACKUP_DIR/nastran_results.tar.gz" -C /
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Installation | On update | Indefinite |
| Input models | Daily | 1 year |
| Results | On completion | Per project (5+ years) |

## Performance Tuning Parameters

### Compiler Optimization

```bash
# Build with optimization flags
gfortran -O3 -march=native -fopenmp -ffast-math \
  -o /opt/nastran95/bin/nastran src/*.f

# With Intel Fortran (recommended for performance)
ifort -O3 -xHost -qopenmp -mkl \
  -o /opt/nastran95/bin/nastran src/*.f
```

### Runtime Parameters

```
# NASTRAN Executive Control
NASTRAN BUFFSIZE=32769
NASTRAN SYSTEM(1)=64  $ Max open files
NASTRAN SYSTEM(151)=1 $ Sparse matrix solver

# Memory allocation
PARAM,AUTOSPC,YES
PARAM,COUPMASS,1
PARAM,BAILOUT,-1
```

### Environment Variables

```bash
export OMP_NUM_THREADS=16
export OMP_STACKSIZE=512M
export MALLOC_MMAP_THRESHOLD_=131072
export OPENBLAS_NUM_THREADS=16
```

## Scaling Procedures

### Vertical Scaling

1. Increase RAM for larger models (model size directly dictates memory needs)
2. Use Intel MKL for optimized matrix operations
3. Increase scratch disk I/O performance (NVMe recommended)
4. Add CPU cores and increase OMP_NUM_THREADS

### Horizontal Scaling

NASTRAN-95 is primarily a single-node application. For workload scaling:

1. Use job scheduler (SLURM) to run multiple analyses concurrently
2. Split large parametric studies across nodes
3. Use distributed scratch storage
4. Queue-based batch processing for model variants

## Emergency Rollback Procedures

```bash
#!/bin/bash
# Rollback NASTRAN-95 installation
PREVIOUS_VERSION="$1"

# Stop any running jobs
scancel --user=nastran 2>/dev/null
pkill -u nastran -f nastran 2>/dev/null

# Restore previous version
rsync -a /opt/nastran95-releases/$PREVIOUS_VERSION/ /opt/nastran95/

# Run validation
/opt/nastran95/tools/nastran-verify.sh
if [ $? -eq 0 ]; then
    echo "Rollback successful - validation passed"
else
    echo "ROLLBACK WARNING - Validation tests failed"
    exit 1
fi
```


## Alerting

### Alert Configuration
- **High CPU Usage** (>80% for 5 minutes): Page on-call engineer
- **High Memory Usage** (>85% for 5 minutes): Page on-call engineer
- **Pod Restart Loop** (>3 restarts in 10 minutes): Page on-call engineer
- **HTTP 5xx Error Rate** (>5% for 2 minutes): Page on-call engineer
- **Response Latency P99** (>2s for 5 minutes): Notify team channel
- **Disk Usage** (>90%): Page on-call engineer

### Alert Channels
- **PagerDuty**: Critical and high-severity alerts
- **Slack (#ops-alerts)**: All alerts including warnings
- **Email**: Daily digest of warning-level alerts


## Monitoring

### Health Check Endpoints
- **Liveness**: `/healthz` — returns 200 if process is running
- **Readiness**: `/readyz` — returns 200 if accepting traffic
- **Metrics**: `/metrics` — Prometheus-format metrics endpoint

### Key Metrics to Monitor
- Request rate (requests/second)
- Error rate (5xx responses / total responses)
- Response latency (P50, P95, P99)
- CPU and memory utilization
- Active database connections
- Pod restart count

### Dashboards
- Grafana: `legacy-modernization` dashboard
- CloudWatch: Custom namespace metrics


## Escalation Procedures

### Escalation Tiers
| Tier | Response Time | Contact | Scope |
|------|--------------|---------|-------|
| L1 — On-Call Engineer | 15 minutes | PagerDuty rotation | Initial triage, known-issue runbook execution |
| L2 — Team Lead | 30 minutes | Slack + phone | Complex issues, requires code-level investigation |
| L3 — Architecture Lead | 1 hour | Direct contact | Systemic issues, cross-service failures |
| L4 — Program Manager | 2 hours | Email + phone | Business-impacting outages, stakeholder communication |

### When to Escalate
- Issue not resolved within 30 minutes at current tier
- Customer-facing impact detected
- Data integrity concerns identified
- Security incident suspected (immediately escalate to L3 + Security team)


## Restart Procedures

### Graceful Restart
```bash
kubectl rollout restart deployment/nastran-95 -n legacy-modernization
kubectl rollout status deployment/nastran-95 -n legacy-modernization --timeout=300s
```

### Force Restart (if graceful fails)
```bash
kubectl delete pod -l app=nastran-95 -n legacy-modernization
kubectl get pods -l app=nastran-95 -n legacy-modernization -w
```

### Post-Restart Verification
1. Confirm all pods are in `Running` state
2. Check readiness probe is passing
3. Verify application logs show successful startup
4. Confirm metrics endpoint is responding
