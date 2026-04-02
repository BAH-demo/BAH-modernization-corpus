# Apache OFBiz Database Migration Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Apache OFBiz |
| **Source Database** | PostgreSQL 12.x (or Derby embedded) |
| **Target Database** | PostgreSQL 14.x+ (modernized) |
| **Estimated Records** | ~10M+ across 800+ tables |
| **Estimated Duration** | 8-12 hours (full migration) |

---

## 1. Migration Strategy

### 1.1 Approach: Parallel Migration with Cutover

```
Phase 1: Schema Analysis and Mapping (Week 1-2)
Phase 2: Schema Migration (Week 3)
Phase 3: Data Migration - Initial Load (Week 4)
Phase 4: Delta Sync and Validation (Week 5)
Phase 5: Cutover (Weekend window)
Phase 6: Post-Migration Validation (Week 6)
```

### 1.2 Key Challenges

| Challenge | Mitigation |
|-----------|-----------|
| OFBiz Entity Engine custom ORM | Map entity definitions to standard SQL DDL |
| 800+ entity tables | Automated schema extraction from entitymodel.xml |
| Custom field types (id, id-long, indicator) | Map to standard PostgreSQL types |
| Seed data vs. transactional data | Separate migration streams |
| Encrypted fields | Re-encrypt with modernized key management |
| View entities (virtual tables) | Convert to PostgreSQL views |

### 1.3 Schema Analysis

OFBiz uses an Entity Engine that defines tables in XML. Key entity groups:

| Entity Group | Table Count | Description |
|-------------|-------------|-------------|
| party | ~50 tables | People, organizations, roles |
| product | ~80 tables | Catalog, categories, features |
| order | ~40 tables | Orders, items, adjustments |
| accounting | ~60 tables | GL, invoices, payments |
| content | ~30 tables | CMS content, data resources |
| workeffort | ~20 tables | Projects, tasks, time tracking |
| shipment | ~25 tables | Shipping, inventory |
| humanres | ~15 tables | HR, employment, benefits |
| marketing | ~10 tables | Campaigns, contact lists |
| manufacturing | ~15 tables | BOM, routing, production |

### 1.4 Data Type Mapping

| OFBiz Type | PostgreSQL Source | PostgreSQL Target |
|-----------|------------------|-------------------|
| id | VARCHAR(20) | VARCHAR(20) |
| id-long | VARCHAR(60) | VARCHAR(60) |
| id-vlong | VARCHAR(255) | VARCHAR(255) |
| indicator | CHAR(1) | CHAR(1) |
| very-short | VARCHAR(10) | VARCHAR(10) |
| short-varchar | VARCHAR(60) | VARCHAR(60) |
| long-varchar | VARCHAR(255) | VARCHAR(255) |
| very-long | TEXT | TEXT |
| name | VARCHAR(100) | VARCHAR(100) |
| description | VARCHAR(255) | VARCHAR(255) |
| comment | VARCHAR(256) | VARCHAR(256) |
| currency-amount | NUMERIC(18,2) | NUMERIC(18,2) |
| currency-precise | NUMERIC(18,3) | NUMERIC(18,3) |
| fixed-point | NUMERIC(18,6) | NUMERIC(18,6) |
| floating-point | DOUBLE PRECISION | DOUBLE PRECISION |
| numeric | NUMERIC(20,0) | BIGINT |
| date-time | TIMESTAMP | TIMESTAMPTZ |
| date | DATE | DATE |
| time | TIME | TIME |
| blob | BYTEA | BYTEA |
| object | BYTEA | JSONB (where applicable) |

---

## 2. Pre-Migration Steps

1. Run pre-migration validation queries (see `apache-ofbiz-pre-migration-checks.sql`)
2. Take full backup of source database
3. Document current table sizes and row counts
4. Verify foreign key relationships
5. Identify and document custom indexes
6. Map OFBiz seed data vs. transactional data
7. Test migration scripts in staging environment

---

## 3. Migration Execution

### 3.1 Schema Migration

```bash
#!/bin/bash
# Extract schema from OFBiz entity engine and create in target
# This generates DDL from OFBiz entity definitions

# Option 1: Direct pg_dump schema
pg_dump -U ofbiz -d ofbiz_source --schema-only > ofbiz_schema.sql

# Apply schema modifications for modernization
# - Add TIMESTAMPTZ where TIMESTAMP exists
# - Add proper constraints
# - Add indexes for common query patterns
# - Convert BYTEA object fields to JSONB where applicable

psql -U ofbiz -d ofbiz_target -f ofbiz_schema_modernized.sql
```

### 3.2 Data Migration

```bash
#!/bin/bash
# Migrate data in dependency order

# Phase 1: Reference/seed data (no FK dependencies)
SEED_TABLES="status_type status_item enumeration_type enumeration geo geo_type"
for table in $SEED_TABLES; do
    pg_dump -U ofbiz -d ofbiz_source --data-only -t $table | \
        psql -U ofbiz -d ofbiz_target
done

# Phase 2: Core entities (party, product)
CORE_TABLES="party person party_group user_login product product_category"
for table in $CORE_TABLES; do
    pg_dump -U ofbiz -d ofbiz_source --data-only -t $table | \
        psql -U ofbiz -d ofbiz_target
done

# Phase 3: Transactional data (orders, accounting)
# Use COPY for large tables for performance
psql -U ofbiz -d ofbiz_source -c "\COPY order_header TO '/tmp/order_header.csv' CSV"
psql -U ofbiz -d ofbiz_target -c "\COPY order_header FROM '/tmp/order_header.csv' CSV"

# Phase 4: Audit and history tables
# These are typically the largest - use parallel COPY
```

### 3.3 Delta Sync

```bash
#!/bin/bash
# Capture changes during migration window using logical replication
# or timestamp-based delta queries

# For tables with lastUpdatedStamp:
psql -U ofbiz -d ofbiz_source -c "
    COPY (SELECT * FROM order_header
          WHERE last_updated_stamp > '$MIGRATION_START_TIME')
    TO '/tmp/order_header_delta.csv' CSV"

psql -U ofbiz -d ofbiz_target -c "
    \COPY order_header FROM '/tmp/order_header_delta.csv' CSV"
```

---

## 4. Post-Migration Validation

1. Run post-migration checks (see `apache-ofbiz-post-migration-checks.sql`)
2. Verify row counts match for all tables
3. Verify checksum/hash on critical data columns
4. Test OFBiz application against migrated database
5. Run OFBiz entity engine validation
6. Performance test critical queries
7. Verify all foreign key constraints satisfied

---

## 5. Rollback Plan

```
If migration fails:
1. Stop application pointing to target database
2. Revert connection string to source database
3. Restart OFBiz against original database
4. Document failure reason
5. Clean target database for re-attempt
```

---

## 6. Timeline

| Phase | Duration | Dependencies |
|-------|----------|-------------|
| Schema analysis | 2 weeks | Access to entity definitions |
| Schema migration | 1 week | Analysis complete |
| Initial data load | 2-3 days | Schema in target |
| Delta sync | 1 day | Initial load complete |
| Validation | 2-3 days | Data loaded |
| Cutover | 4-8 hours (downtime window) | Validation passed |
| Post-cutover monitoring | 1 week | Cutover complete |
