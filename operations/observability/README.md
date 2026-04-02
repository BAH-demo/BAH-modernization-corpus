# Observability Stack - Setup and Configuration

## Overview

This directory contains the complete observability configuration for the Federal Modernization Portfolio's 13 legacy systems. The stack provides metrics collection, alerting, log aggregation, and visualization.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Observability Stack                       │
│                                                             │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │  Prometheus   │  │ AlertManager  │  │    Grafana       │ │
│  │  (Metrics)    │──│  (Routing)    │  │  (Dashboards)    │ │
│  └──────┬───────┘  └───────────────┘  └────────┬─────────┘ │
│         │                                       │           │
│  ┌──────┴───────┐                      ┌────────┴─────────┐ │
│  │   Exporters   │                      │  Elasticsearch   │ │
│  │  (per system) │                      │  (Log Storage)   │ │
│  └──────────────┘                      └────────┬─────────┘ │
│                                                 │           │
│                                        ┌────────┴─────────┐ │
│                                        │    Fluentd       │ │
│                                        │  (Log Collector) │ │
│                                        └──────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Components

| Component | Version | Purpose | Config File |
|-----------|---------|---------|-------------|
| Prometheus | 2.45+ | Metrics collection and alerting rules | `prometheus-rules.yaml` |
| AlertManager | 0.26+ | Alert routing and notification | `alertmanager-config.yaml` |
| Grafana | 10.x+ | Dashboards and visualization | `grafana-dashboards/` |
| Elasticsearch | 8.x | Log storage and search | `logging-config.yaml` |
| Fluentd | 1.16+ | Log collection agent | `logging-config.yaml` |
| Kibana | 8.x | Log visualization | `logging-config.yaml` |

## Systems Monitored

| System | Language | Metrics Exporter | Log Source |
|--------|----------|------------------|------------|
| Apache OFBiz | Java | JMX Exporter | `/opt/ofbiz/runtime/logs/` |
| Alfresco Community | Java | JMX Exporter | `/opt/alfresco/tomcat/logs/` |
| Nuxeo | Java | JMX Exporter + Nuxeo Metrics | `/var/log/nuxeo/` |
| B2CWeb | Java | JMX Exporter | `/opt/tomcat/logs/` |
| Monolith Enterprise | Java | JMX Exporter + WildFly Metrics | `/opt/wildfly/standalone/log/` |
| Odoo | Python | Custom Prometheus Client | `/var/log/odoo/` |
| Django Oscar | Python | django-prometheus | `/var/log/oscar/` |
| Mezzanine | Python | django-prometheus | `/var/log/mezzanine/` |
| Umbraco CMS | C# | prometheus-net | `/opt/umbraco/umbraco/Logs/` |
| DFe-NET | C# | prometheus-net | `/var/log/dfe-net/` |
| CFWheels | ColdFusion | JMX Exporter | `/opt/lucee/web/logs/` |
| NASTRAN-95 | Fortran | Custom Node Exporter | `/data/nastran/results/` |
| Apollo-11 | Assembly | Custom Node Exporter | `/opt/virtualagc/` |

## Setup Instructions

### Prerequisites

- Docker and Docker Compose (for containerized deployment) or systemd-managed services
- Network connectivity between all 13 system hosts and the observability stack
- TLS certificates for encrypted communication
- FedRAMP-compliant cloud environment (if cloud-hosted)

### 1. Deploy Prometheus

```bash
# Install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xzf prometheus-2.45.0.linux-amd64.tar.gz
sudo mv prometheus-2.45.0.linux-amd64 /opt/prometheus

# Copy alerting rules
sudo cp prometheus-rules.yaml /opt/prometheus/rules/

# Configure prometheus.yml to include:
# rule_files:
#   - "rules/prometheus-rules.yaml"
# scrape_configs for all 13 systems

# Start Prometheus
sudo systemctl start prometheus
```

### 2. Deploy AlertManager

```bash
# Install AlertManager
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar xzf alertmanager-0.26.0.linux-amd64.tar.gz
sudo mv alertmanager-0.26.0.linux-amd64 /opt/alertmanager

# Copy configuration
sudo cp alertmanager-config.yaml /opt/alertmanager/alertmanager.yml

# Configure secrets
sudo mkdir -p /etc/alertmanager/secrets
# Place PagerDuty keys, Slack webhooks, SMTP passwords in secrets directory

# Start AlertManager
sudo systemctl start alertmanager
```

### 3. Deploy Grafana

```bash
# Install Grafana
sudo apt-get install -y grafana

# Copy dashboards
sudo cp -r grafana-dashboards/ /var/lib/grafana/dashboards/

# Configure Grafana data sources (Prometheus + Elasticsearch)
# Add to /etc/grafana/provisioning/datasources/

# Start Grafana
sudo systemctl start grafana-server
```

### 4. Deploy ELK Stack + Fluentd

```bash
# Install Elasticsearch
sudo apt-get install -y elasticsearch

# Install Kibana
sudo apt-get install -y kibana

# Install Fluentd on each application host
curl -fsSL https://toolbelt.treasuredata.com/sh/install-ubuntu-jammy-fluent-package5-lts.sh | sh

# Configure Fluentd using logging-config.yaml
# Copy appropriate sections to /etc/fluent/fluent.conf on each host

# Start services
sudo systemctl start elasticsearch
sudo systemctl start kibana
sudo systemctl start fluentd
```

### 5. Install Metrics Exporters

#### Java Systems (OFBiz, Alfresco, Nuxeo, B2CWeb, Monolith)

```bash
# Download JMX Exporter
wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.19.0/jmx_prometheus_javaagent-0.19.0.jar

# Add to Java startup arguments:
# -javaagent:/opt/jmx_exporter/jmx_prometheus_javaagent-0.19.0.jar=9090:/opt/jmx_exporter/config.yaml
```

#### Python Systems (Odoo, Django Oscar, Mezzanine)

```bash
# Install django-prometheus (for Django-based systems)
pip install django-prometheus

# Add to Django INSTALLED_APPS and MIDDLEWARE
# See django-prometheus documentation for details
```

#### C# Systems (Umbraco, DFe-NET)

```bash
# Install prometheus-net NuGet package
dotnet add package prometheus-net.AspNetCore

# Add to Program.cs:
# app.UseHttpMetrics();
# app.MapMetrics();
```

## Verification

After deployment, verify the stack is operational:

```bash
# Check Prometheus targets
curl http://prometheus:9090/api/v1/targets | python3 -m json.tool

# Check AlertManager
curl http://alertmanager:9093/api/v2/status

# Check Grafana
curl http://grafana:3000/api/health

# Check Elasticsearch
curl http://elasticsearch:9200/_cluster/health

# Verify logs are flowing
curl "http://elasticsearch:9200/modernization-*/_count"
```

## Maintenance

| Task | Frequency | Procedure |
|------|-----------|-----------|
| Review alert rules | Monthly | Update thresholds based on baselines |
| Update dashboards | Monthly | Add new panels for emerging patterns |
| Rotate log indices | Automated (ILM) | Managed by Elasticsearch ILM policy |
| Test alert routing | Quarterly | Send test alerts through all channels |
| Review disk usage | Weekly | Monitor Elasticsearch and Prometheus storage |
| Update exporters | Quarterly | Keep exporters at latest stable versions |

## Troubleshooting

### No metrics from a system

1. Check if the exporter is running on the target host
2. Verify network connectivity (port accessible from Prometheus)
3. Check Prometheus targets page for scrape errors
4. Review exporter logs on the target host

### Alerts not firing

1. Check Prometheus rule evaluation: `curl http://prometheus:9090/api/v1/rules`
2. Verify AlertManager is receiving alerts: `curl http://alertmanager:9093/api/v2/alerts`
3. Check AlertManager routing configuration
4. Review inhibition rules for suppressed alerts

### Logs not appearing in Kibana

1. Check Fluentd status on the source host: `sudo systemctl status fluentd`
2. Verify Fluentd buffer is not full: `ls -la /var/log/fluentd/buffer/`
3. Check Elasticsearch index exists: `curl http://elasticsearch:9200/_cat/indices`
4. Review Fluentd logs: `journalctl -u fluentd -f`
