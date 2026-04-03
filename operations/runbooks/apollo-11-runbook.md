# Apollo-11 Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Apollo-11 Guidance Computer (AGC) |
| **Type** | Historic Software Preservation |
| **Language** | Assembly (AGC Assembly) |
| **Tier** | Tier 3 - Federal/Legacy System |
| **LOC** | 8,000+ |
| **Category** | Aerospace / Historic Preservation |
| **Criticality** | Medium (preservation/research) |

### Architecture

Apollo-11 AGC software is a preserved Assembly codebase from the Apollo Guidance Computer:

- **Luminary (LM)**: Lunar Module guidance software
- **Comanche (CM)**: Command Module guidance software
- **Executive**: Real-time task scheduling and priority management
- **Interpreter**: Double-precision math and navigation routines
- **Digital Autopilot**: Attitude control and engine management
- **Navigation**: Celestial/inertial navigation computations

```
┌─────────────────────────────────────────┐
│        Research / Analysis Layer         │
│  (Modern tools for studying AGC code)   │
├─────────────────────────────────────────┤
│          AGC Simulator (yaAGC)          │
│  ┌──────────┐ ┌───────────┐ ┌────────┐ │
│  │Executive │ │Interpreter│ │  DAP   │ │
│  │(Waitlist)│ │(Math Lib) │ │(Pilot) │ │
│  └──────────┘ └───────────┘ └────────┘ │
├─────────────────────────────────────────┤
│    AGC Assembler    │   DSKY Simulator  │
│    (yaYUL)          │   (yaDSKY)        │
└─────────────────────┴───────────────────┘
```

## Prerequisites and Dependencies

### System Requirements (Simulation/Analysis Environment)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 2 GB | 4 GB |
| Disk | 5 GB | 10 GB |
| OS | RHEL 8+ / Ubuntu 20.04+ / macOS 12+ | Ubuntu 22.04 |

### Software Dependencies

- GCC/G++ (building yaAGC tools)
- Python 3.8+ (analysis scripts)
- yaAGC suite (AGC simulator, assembler, DSKY emulator)
- Git (source management)
- Make/CMake (build system)
- wxWidgets (optional, for yaDSKY GUI)
- Tcl/Tk (optional, for DSKY display)

### Build Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install build-essential git python3 python3-pip \
  libwxgtk3.0-gtk3-dev tcl-dev tk-dev libsdl2-dev libncurses-dev

# RHEL/CentOS
sudo dnf install gcc gcc-c++ make git python3 \
  wxGTK3-devel tcl-devel tk-devel SDL2-devel ncurses-devel
```

## Startup and Shutdown Procedures

### Building the AGC Simulator

```bash
# Clone and build yaAGC
cd /opt
git clone https://github.com/virtualagc/virtualagc.git
cd virtualagc
make

# Build specific mission software
cd /opt/virtualagc
make Luminary099   # Lunar Module (Apollo 11)
make Comanche055   # Command Module (Apollo 11)
```

### Running the AGC Simulator

```bash
# Start AGC simulation (Luminary - Lunar Module)
cd /opt/virtualagc
./yaAGC --core=Luminary099/Luminary099.agc.bin &

# Start DSKY interface
./yaDSKY --cfg=LM.ini &

# Start telemetry display (optional)
./yaTelemetry &
```

### Assembling Source Code

```bash
# Assemble Luminary099 source
cd /opt/virtualagc
./yaYUL Luminary099/MAIN.agc > assembly_output.log 2>&1

# Verify assembly matches reference binary
diff Luminary099/Luminary099.agc.bin Luminary099/Luminary099.agc.bin.reference
```

### Shutting Down Simulator

```bash
# Graceful shutdown
pkill yaAGC
pkill yaDSKY
pkill yaTelemetry
```

## Health Check and Validation

### Code Integrity Verification

```bash
#!/bin/bash
# apollo11-verify.sh

# Verify source checksum integrity
cd /opt/apollo11-source

echo "Verifying Luminary099 (LM)..."
sha256sum -c Luminary099/checksums.sha256
if [ $? -ne 0 ]; then
    echo "CRITICAL: Luminary099 source integrity check FAILED"
    exit 2
fi

echo "Verifying Comanche055 (CM)..."
sha256sum -c Comanche055/checksums.sha256
if [ $? -ne 0 ]; then
    echo "CRITICAL: Comanche055 source integrity check FAILED"
    exit 2
fi

# Verify assembly produces correct binary
cd /opt/virtualagc
./yaYUL Luminary099/MAIN.agc > /dev/null 2>&1
if ! diff -q Luminary099/Luminary099.agc.bin Luminary099/Luminary099.agc.bin.reference > /dev/null 2>&1; then
    echo "WARNING: Assembly output differs from reference binary"
    exit 1
fi

echo "OK: Apollo-11 code integrity verified"
exit 0
```

### Simulator Validation

```bash
#!/bin/bash
# Run automated test scenarios
cd /opt/virtualagc/test-scripts

python3 agc_test_runner.py \
  --program=Luminary099 \
  --test-suite=basic_operations \
  --timeout=60

if [ $? -eq 0 ]; then
    echo "OK: Simulator validation passed"
else
    echo "FAIL: Simulator validation failed"
    exit 1
fi
```

## Common Troubleshooting Scenarios

### 1. Assembly Errors

**Symptoms**: yaYUL reports errors; binary doesn't match reference

**Resolution**:
```bash
# Check assembly log for errors
./yaYUL Luminary099/MAIN.agc 2>&1 | grep -i "error\|warning"

# Verify source files are unmodified
git status
git diff --stat HEAD

# Reset to known good state
git checkout -- Luminary099/
```

### 2. Simulator Crash

**Symptoms**: yaAGC segfault; unexpected termination

**Resolution**:
```bash
# Run with debug output
./yaAGC --core=Luminary099/Luminary099.agc.bin --debug > /tmp/agc_debug.log 2>&1

# Check for corrupt binary
file Luminary099/Luminary099.agc.bin
ls -la Luminary099/Luminary099.agc.bin

# Rebuild
make clean && make Luminary099
```

### 3. DSKY Display Not Connecting

**Symptoms**: DSKY shows no data; connection timeout

**Resolution**:
```bash
# Check yaAGC is running and listening
netstat -tlnp | grep yaAGC

# Verify port configuration
cat LM.ini | grep port

# Restart in correct order (AGC first, then DSKY)
pkill yaDSKY; pkill yaAGC
sleep 2
./yaAGC --core=Luminary099/Luminary099.agc.bin &
sleep 1
./yaDSKY --cfg=LM.ini &
```

### 4. Source Code Encoding Issues

**Symptoms**: Files display incorrectly; special characters corrupted

**Resolution**:
```bash
# Check file encoding
file Luminary099/*.agc

# AGC source uses ASCII
# Convert if needed
iconv -f utf-8 -t ascii//TRANSLIT input.agc > output.agc

# Verify line endings (should be Unix-style LF)
file Luminary099/MAIN.agc | grep -i "crlf"
dos2unix Luminary099/*.agc  # if needed
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Assembly Log | `/opt/virtualagc/assembly.log` | yaYUL assembler output |
| Simulator Log | `/opt/virtualagc/yaAGC.log` | AGC simulator trace |
| Debug Trace | `/opt/virtualagc/debug.log` | Instruction-level trace |
| Test Results | `/opt/virtualagc/test-results/` | Validation test outputs |

### Log Analysis Commands

```bash
# Check assembly warnings
grep -c "WARNING\|ERROR" /opt/virtualagc/assembly.log

# Trace program execution
grep "VERB\|NOUN\|PROGRAM" /opt/virtualagc/yaAGC.log | tail -50

# Check memory usage patterns
grep "ERASABLE\|FIXED" /opt/virtualagc/assembly.log | tail -20
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/apollo11/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Source code (critical preservation artifact)
tar czf "$BACKUP_DIR/apollo11_source.tar.gz" /opt/apollo11-source/

# Built binaries and tools
tar czf "$BACKUP_DIR/virtualagc_tools.tar.gz" /opt/virtualagc/

# Research artifacts
tar czf "$BACKUP_DIR/apollo11_research.tar.gz" /data/apollo11-research/

# Generate checksums
cd "$BACKUP_DIR"
sha256sum *.tar.gz > checksums.sha256

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

# Verify integrity
cd "$BACKUP_DIR"
sha256sum -c checksums.sha256 || { echo "INTEGRITY CHECK FAILED"; exit 1; }

tar xzf "$BACKUP_DIR/apollo11_source.tar.gz" -C /
tar xzf "$BACKUP_DIR/virtualagc_tools.tar.gz" -C /
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Source code | On any change | Indefinite (permanent preservation) |
| Tools/binaries | On rebuild | 5 versions |
| Research data | Weekly | 1 year |

## Performance Tuning Parameters

### Build Optimization

```bash
# Optimize yaAGC build
CFLAGS="-O2 -march=native" make

# For faster simulation
CFLAGS="-O3 -march=native -flto" make yaAGC
```

### Simulation Parameters

```bash
# Real-time simulation (1x speed)
./yaAGC --core=Luminary099.agc.bin --real-time

# Accelerated simulation (for testing)
./yaAGC --core=Luminary099.agc.bin --max-speed

# Debug mode (slower, more output)
./yaAGC --core=Luminary099.agc.bin --debug --trace
```

## Scaling Procedures

### Research Scaling

NASTRAN and Apollo-11 are single-instance research systems. Scaling applies to research throughput:

1. Run multiple simulator instances for different mission phases
2. Parallelize analysis scripts across compute nodes
3. Use containerization for reproducible research environments

### Containerized Research Environment

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y build-essential git python3
COPY . /opt/virtualagc
WORKDIR /opt/virtualagc
RUN make
CMD ["./yaAGC", "--core=Luminary099/Luminary099.agc.bin"]
```

## Emergency Rollback Procedures

```bash
#!/bin/bash
# apollo11-rollback.sh
# Restore source code to known-good state

cd /opt/apollo11-source

# Git-based rollback
git fetch origin
git checkout origin/master -- .

# Verify integrity
sha256sum -c checksums.sha256
if [ $? -eq 0 ]; then
    echo "Rollback successful - source integrity verified"
else
    echo "WARNING: Post-rollback integrity check failed"
    # Restore from backup
    tar xzf /backup/apollo11/latest/apollo11_source.tar.gz -C /
    echo "Restored from backup"
fi

# Rebuild tools
cd /opt/virtualagc
make clean && make
```

## Special Considerations

### Preservation Requirements

- Source code is a **historic artifact** - never modify the original AGC assembly source
- All analysis and research should use copies, not originals
- Maintain provenance chain for all preserved artifacts
- Follow NARA (National Archives) digital preservation standards
- SHA-256 checksums must be verified on every access

### Research Usage Guidelines

1. Always work on a branch or copy, never modify master/main source
2. Document all analysis methodologies and findings
3. Cross-reference with original MIT Instrumentation Lab documentation
4. Verify simulator behavior against known mission telemetry data
5. Preserve all research artifacts with metadata


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
